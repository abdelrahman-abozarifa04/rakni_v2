import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import * as crypto from "crypto";

// ---------------------------------------------------------------------------
// Initialization
// ---------------------------------------------------------------------------

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// Email transporter
//
// Configure via Firebase environment variables (set before deploying):
//   firebase functions:secrets:set MAIL_USER
//   firebase functions:secrets:set MAIL_PASS
//
// Or using legacy config:
//   firebase functions:config:set mail.user="your@email.com" mail.pass="yourpassword"
//
// For Gmail you must enable "App Passwords" (2FA required).
// ---------------------------------------------------------------------------

function createTransporter() {
  const user = process.env.MAIL_USER ?? functions.config().mail?.user;
  const pass = process.env.MAIL_PASS ?? functions.config().mail?.pass;

  if (!user || !pass) {
    throw new Error("Missing mail configuration (user or pass).");
  }

  return nodemailer.createTransport({
    service: "gmail",
    auth: { user, pass },
  });
}

function getFromAddress() {
  return `"Rakni" <${process.env.MAIL_USER ?? functions.config().mail?.user}>`;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Helper to generate a random 6-digit OTP
 * @return {string} 6-digit code
 */
function generateOtp(): string {
  return crypto.randomInt(100000, 999999).toString();
}

/** Returns a Firestore Timestamp 10 minutes from now. */
function tenMinutesFromNow(): admin.firestore.Timestamp {
  const ms = Date.now() + 10 * 60 * 1000;
  return admin.firestore.Timestamp.fromMillis(ms);
}

/** Builds a clean HTML email body for the given OTP and purpose. */
function buildEmailHtml(otp: string, type: "verification" | "password_reset"): string {
  const subject =
    type === "verification" ? "Verify your Rakni account" : "Reset your Rakni password";
  const action =
    type === "verification"
      ? "verify your email address"
      : "reset your password";

  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
      <title>${subject}</title>
    </head>
    <body style="margin:0;padding:0;background:#0E0E12;font-family:'SF Pro Display',Arial,sans-serif;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background:#0E0E12;padding:40px 0;">
        <tr>
          <td align="center">
            <table width="480" cellpadding="0" cellspacing="0"
              style="background:#1A1A1F;border-radius:16px;overflow:hidden;border:1px solid #2A2A2B;">
              <!-- Header -->
              <tr>
                <td style="background:#BDE500;padding:24px;text-align:center;">
                  <span style="font-size:28px;font-weight:700;color:#0E0E12;letter-spacing:-0.5px;">
                    RAKNI
                  </span>
                </td>
              </tr>
              <!-- Body -->
              <tr>
                <td style="padding:40px 32px;">
                  <p style="color:#FFFFFF;font-size:18px;font-weight:600;margin:0 0 8px;">
                    ${subject}
                  </p>
                  <p style="color:#99A1AF;font-size:14px;margin:0 0 32px;line-height:1.6;">
                    Use the code below to ${action}.
                    This code expires in <strong style="color:#FFFFFF;">10 minutes</strong>.
                  </p>
                  <!-- OTP block -->
                  <div style="background:#2A2A2B;border-radius:12px;padding:24px;text-align:center;
                              letter-spacing:16px;font-size:40px;font-weight:700;color:#BDE500;
                              margin-bottom:32px;">
                    ${otp}
                  </div>
                  <p style="color:#6A7282;font-size:12px;margin:0;line-height:1.5;">
                    If you did not request this, you can safely ignore this email.
                    Do not share this code with anyone.
                  </p>
                </td>
              </tr>
              <!-- Footer -->
              <tr>
                <td style="padding:16px 32px;border-top:1px solid #2A2A2B;text-align:center;">
                  <span style="color:#6A7282;font-size:11px;">
                    © ${new Date().getFullYear()} Rakni. All rights reserved.
                  </span>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `;
}

// ===========================================================================
// FUNCTION 1 — sendVerificationOTP
// ===========================================================================

export const sendVerificationOTP = functions
  .region("europe-west1")
  .https.onCall(async (data: { email: string; uid: string }, context) => {
    const email: string = (data.email ?? "").trim().toLowerCase();
    const uid: string = (data.uid ?? "").trim();

    if (!email || !uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Both 'email' and 'uid' are required."
      );
    }

    const code = generateOtp();

    await db.collection("otps").doc(email).set({
      code,
      type: "verification",
      uid,
      expiresAt: tenMinutesFromNow(),
      used: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[OTP] Sent to ${email}: ${code}`);

    try {
      const transporter = createTransporter();
      await transporter.sendMail({
        from: getFromAddress(),
        to: email,
        subject: "Your Rakni verification code",
        html: buildEmailHtml(code, "verification"),
      });
    } catch (error) {
      console.error("Email sending failed:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send verification email. Please contact support."
      );
    }

    return { success: true };
  });

// ===========================================================================
// FUNCTION 2 — sendPasswordResetOTP
// ===========================================================================

export const sendPasswordResetOTP = functions
  .region("europe-west1")
  .https.onCall(async (data: { email: string }, _context) => {
    const email: string = (data.email ?? "").trim().toLowerCase();

    if (!email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "'email' is required."
      );
    }

    const code = generateOtp();

    await db.collection("otps").doc(email).set({
      code,
      type: "password_reset",
      expiresAt: tenMinutesFromNow(),
      used: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[OTP] Sent to ${email}: ${code}`);

    try {
      const transporter = createTransporter();
      await transporter.sendMail({
        from: getFromAddress(),
        to: email,
        subject: "Your Rakni password reset code",
        html: buildEmailHtml(code, "password_reset"),
      });
    } catch (error) {
      console.error("Email sending failed:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send password reset email. Please contact support."
      );
    }

    return { success: true };
  });

// ===========================================================================
// FUNCTION 3 — verifyOTP
// ===========================================================================

export const verifyOTP = functions
  .region("europe-west1")
  .https.onCall(
    async (
      data: { email: string; code: string; type: string },
      _context
    ) => {
      const email: string = (data.email ?? "").trim().toLowerCase();
      const code: string = (data.code ?? "").trim();
      const type: string = (data.type ?? "").trim();

      if (!email || !code || !type) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "'email', 'code', and 'type' are all required."
        );
      }

      if (type !== "verification" && type !== "password_reset") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "'type' must be 'verification' or 'password_reset'."
        );
      }

      const docRef = db.collection("otps").doc(email);
      const snapshot = await docRef.get();

      if (!snapshot.exists) {
        return { success: false, error: "No OTP found for this email." };
      }

      const record = snapshot.data() as any;

      console.log(`[OTP] Verifying ${type} for ${email}. Record code: ${record.code}, Input code: ${code}`);

      if (record.type !== type) {
        return { success: false, error: "OTP type mismatch." };
      }

      if (record.used === true) {
        return { success: false, error: "This OTP has already been used." };
      }

      const now = admin.firestore.Timestamp.now();
      if (record.expiresAt.toMillis() < now.toMillis()) {
        return { success: false, error: "This OTP has expired. Please request a new one." };
      }

      if (record.code !== code) {
        return { success: false, error: "Invalid OTP code." };
      }

      if (type === "verification" && record.uid) {
        try {
          await admin.auth().updateUser(record.uid, { emailVerified: true });
          console.log(`[OTP] User ${record.uid} (${email}) marked as emailVerified: true`);
        } catch (error) {
          console.error("Error updating user verification status:", error);
          throw new functions.https.HttpsError("internal", "Failed to verify user account.");
        }
      }

      await docRef.update({ used: true });
      console.log(`[OTP] Code for ${email} marked as used.`);

      return { success: true };
    }
  );
