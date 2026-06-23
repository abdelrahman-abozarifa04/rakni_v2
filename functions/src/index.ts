import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { Resend } from "resend";
import * as crypto from "crypto";

// ---------------------------------------------------------------------------
// Initialization
// ---------------------------------------------------------------------------

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// Resend Configuration
//
// Resend is used instead of SendGrid because:
//   1. Free tier: 3,000 emails/month, 100/day — no cost
//   2. Can send from their shared trusted domain (onboarding@resend.dev)
//      without needing your own domain
//   3. Excellent deliverability — emails go to inbox, not spam
//
// Steps:
//   1. Sign up free at https://resend.com
//   2. Get your API key from the Resend dashboard
//   3. Run: firebase functions:secrets:set RESEND_API_KEY
//      Paste your Resend API key when prompted
//   4. Deploy: firebase deploy --only functions
//
// FROM email options:
//   - FREE (no domain needed): "onboarding@resend.dev"
//   - With your own domain: "noreply@yourdomain.com" (after domain auth in Resend)
// ---------------------------------------------------------------------------

// Use your verified custom domain rakni.xyz
const RESEND_FROM_EMAIL =
  process.env.RESEND_FROM_EMAIL ??
  "noreply@rakni.xyz";

const RESEND_FROM_NAME =
  process.env.RESEND_FROM_NAME ??
  "Rakni";

const ACTION_HANDLER_BASE_URL =
  process.env.AUTH_ACTION_HANDLER_URL ??
  (functions.config().auth as { action_url?: string } | undefined)?.action_url ??
  "https://rakni-v2.web.app";

function getResendClient(): Resend {
  const apiKey =
    process.env.RESEND_API_KEY ??
    (functions.config().resend as { key?: string } | undefined)?.key;

  if (!apiKey) {
    console.error("[Resend] RESEND_API_KEY is not set. Emails will fail.");
    throw new Error("RESEND_API_KEY is not configured.");
  }
  return new Resend(apiKey);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function generateOtp(): string {
  return crypto.randomInt(100000, 999999).toString();
}

function tenMinutesFromNow(): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000);
}

function buildActionUrl(rawLink: string, mode: "verifyEmail" | "resetPassword") {
  const parsed = new URL(rawLink);
  const oobCode = parsed.searchParams.get("oobCode");
  if (!oobCode) {
    throw new Error("Missing oobCode in action link");
  }

  const actionUrl = new URL(ACTION_HANDLER_BASE_URL);
  actionUrl.searchParams.set("mode", mode);
  actionUrl.searchParams.set("oobCode", oobCode);
  actionUrl.searchParams.set("lang", "en");
  return actionUrl.toString();
}

// ---------------------------------------------------------------------------
// Premium Email Template
// ---------------------------------------------------------------------------

function buildEmailHtml(
  otp: string,
  type: "verification" | "password_reset"
): string {
  const isVerification = type === "verification";

  const title = isVerification ? "Verify Your Email" : "Reset Your Password";
  const subTitle = isVerification
    ? "You're almost there! Enter this code in the Rakni app to verify your account."
    : "Use the code below to reset your Rakni account password. Never share this code with anyone.";
  const iconSvg = isVerification
    ? /* shield-check */
      `<svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 2L4 6v6c0 5.25 3.5 10.15 8 11.35C16.5 22.15 20 17.25 20 12V6l-8-4z" fill="rgba(189,229,0,0.15)" stroke="#BDE500" stroke-width="1.5" stroke-linejoin="round"/>
        <path d="M9 12l2 2 4-4" stroke="#BDE500" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>`
    : /* key */
      `<svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="9" cy="9" r="5" fill="rgba(189,229,0,0.15)" stroke="#BDE500" stroke-width="1.5"/>
        <path d="M14 14l6 6" stroke="#BDE500" stroke-width="2" stroke-linecap="round"/>
        <path d="M17 17l2-2" stroke="#BDE500" stroke-width="2" stroke-linecap="round"/>
      </svg>`;

  // Split OTP into individual digits for individual boxes
  const otpDigits = otp
    .split("")
    .map(
      (d) =>
        `<td style="padding:0 5px;">
          <div style="
            width:48px;height:60px;
            background:rgba(189,229,0,0.06);
            border:1.5px solid rgba(189,229,0,0.3);
            border-radius:12px;
            font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;
            font-size:28px;font-weight:700;
            color:#BDE500;
            line-height:60px;
            text-align:center;
            display:inline-block;
          ">${d}</div>
        </td>`
    )
    .join("");

  return `<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1.0"/>
  <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
  <meta name="color-scheme" content="dark"/>
  <meta name="supported-color-schemes" content="dark"/>
  <title>${title} – Rakni</title>
  <!--[if mso]>
  <noscript>
    <xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml>
  </noscript>
  <![endif]-->
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
    body,table,td,a{-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;}
    table,td{mso-table-lspace:0pt;mso-table-rspace:0pt;}
    img{-ms-interpolation-mode:bicubic;border:0;line-height:100%;outline:none;text-decoration:none;}
    @media only screen and (max-width:600px){
      .wrapper{width:100%!important;}
      .otp-digit{width:36px!important;height:48px!important;font-size:22px!important;line-height:48px!important;}
      .content-pad{padding:32px 24px!important;}
    }
  </style>
</head>
<body style="margin:0;padding:0;background-color:#1A1A1B;font-family:'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <!-- Preheader (hidden preview text) -->
  <div style="display:none;font-size:1px;color:#1A1A1B;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">
    ${isVerification ? `Your Rakni verification code is ${otp} — expires in 10 minutes.` : `Your Rakni password reset code is ${otp} — expires in 10 minutes.`}
  </div>

  <!-- Wrapper -->
  <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color:#1A1A1B;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <!-- Card -->
        <table class="wrapper" border="0" cellpadding="0" cellspacing="0" width="520"
          style="background-color:#111112;border-radius:24px;border:1px solid rgba(255,255,255,0.08);overflow:hidden;box-shadow:0 32px 64px rgba(0,0,0,0.6);">

          <!-- Top accent bar -->
          <tr>
            <td style="background:linear-gradient(90deg,#BDE500 0%,#8fb800 100%);height:3px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <!-- Header -->
          <tr>
            <td align="center" style="padding:48px 48px 32px 48px;">
              <!-- Logo mark -->
              <table border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <!-- Logo -->
                    <div style="
                      width:174px;height:auto;
                      display:inline-block;
                      text-align:center;
                      margin-bottom:20px;
                    ">
                      <img src="https://rakni-v2.web.app/rakni_logo_white.png" alt="Rakni" width="174" height="52" style="display:block;width:174px;max-width:174px;height:auto;border:0;outline:none;text-decoration:none;"/>
                    </div>
                  </td>
                </tr>
                <tr>
                  <td align="center" style="padding-bottom:6px;">
                    <span style="font-size:22px;font-weight:700;color:#FFFFFF;letter-spacing:-0.5px;">Rakni</span>
                    &nbsp;
                    <span style="font-size:13px;color:rgba(255,255,255,0.35);font-weight:400;">ركني</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 48px;">
              <div style="height:1px;background:rgba(255,255,255,0.06);font-size:0;line-height:0;">&nbsp;</div>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td class="content-pad" style="padding:40px 48px;">

              <!-- Icon + title -->
              <table border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="center" style="padding-bottom:20px;">
                    <div style="
                      width:64px;height:64px;
                      background:rgba(189,229,0,0.08);
                      border:1px solid rgba(189,229,0,0.2);
                      border-radius:16px;
                      display:inline-block;
                      text-align:center;
                      line-height:68px;
                    ">
                      ${iconSvg}
                    </div>
                  </td>
                </tr>
                <tr>
                  <td align="center" style="padding-bottom:12px;">
                    <h1 style="margin:0;font-size:24px;font-weight:700;color:#FFFFFF;letter-spacing:-0.5px;">${title}</h1>
                  </td>
                </tr>
                <tr>
                  <td align="center" style="padding-bottom:36px;">
                    <p style="margin:0;font-size:15px;color:rgba(255,255,255,0.6);line-height:1.7;max-width:340px;text-align:center;">
                      ${subTitle}
                    </p>
                  </td>
                </tr>
              </table>

              <!-- OTP Digits -->
              <table border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="center" style="padding-bottom:28px;">
                    <table border="0" cellpadding="0" cellspacing="0">
                      <tr>
                        ${otpDigits}
                      </tr>
                    </table>
                    <p style="margin:16px 0 0 0;font-size:12px;color:rgba(255,255,255,0.35);text-transform:uppercase;letter-spacing:1.5px;">
                      ⏱ Expires in 10 minutes
                    </p>
                  </td>
                </tr>
              </table>

              <!-- Info box -->
              <table border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td style="
                    background:rgba(255,255,255,0.03);
                    border:1px solid rgba(255,255,255,0.07);
                    border-radius:14px;
                    padding:18px 20px;
                  ">
                    <p style="margin:0;font-size:13px;color:rgba(255,255,255,0.45);line-height:1.7;text-align:center;">
                      🔒&nbsp; If you didn't request this code, please ignore this email.
                      Your account remains secure and no action is needed.
                    </p>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:28px 48px 40px;background-color:rgba(0,0,0,0.25);border-top:1px solid rgba(255,255,255,0.05);">
              <table border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center" style="padding-bottom:14px;">
                    <a href="https://rakni-v2.web.app" style="color:rgba(255,255,255,0.3);font-size:12px;text-decoration:none;margin:0 12px;">Website</a>
                    <a href="mailto:as0144549@gmail.com" style="color:rgba(255,255,255,0.3);font-size:12px;text-decoration:none;margin:0 12px;">Support</a>
                    <a href="https://rakni-v2.web.app" style="color:rgba(255,255,255,0.3);font-size:12px;text-decoration:none;margin:0 12px;">Privacy</a>
                  </td>
                </tr>
                <tr>
                  <td align="center">
                    <p style="margin:0;font-size:11px;color:rgba(255,255,255,0.2);line-height:1.7;">
                      © ${new Date().getFullYear()} Rakni — Smart Parking.<br/>
                      You're receiving this because you signed up for a Rakni account.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

        </table>
        <!-- /Card -->

      </td>
    </tr>
  </table>

</body>
</html>`;
}

function buildActionEmailHtml(
  actionUrl: string,
  type: "verification" | "password_reset"
): string {
  const isVerification = type === "verification";
  const title = isVerification ? "Verify Your Email" : "Reset Your Password";
  const subTitle = isVerification
    ? "Confirm your Rakni account to start booking parking in minutes."
    : "Create a new password to secure your Rakni account.";
  const cta = isVerification ? "Verify Email" : "Reset Password";
  const safeActionUrl = actionUrl.replace(/&/g, "&amp;");

  return `<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1.0"/>
  <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
  <meta name="color-scheme" content="dark"/>
  <meta name="supported-color-schemes" content="dark"/>
  <title>${title} – Rakni</title>
  <!--[if mso]>
  <noscript>
    <xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml>
  </noscript>
  <![endif]-->
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
    body,table,td,a{-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;}
    table,td{mso-table-lspace:0pt;mso-table-rspace:0pt;}
    img{-ms-interpolation-mode:bicubic;border:0;line-height:100%;outline:none;text-decoration:none;}
    @media only screen and (max-width:600px){
      .wrapper{width:100%!important;}
      .content-pad{padding:32px 24px!important;}
    }
  </style>
</head>
<body style="margin:0;padding:0;background-color:#1A1A1B;font-family:'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

  <div style="display:none;font-size:1px;color:#1A1A1B;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">
    ${isVerification ? "Verify your Rakni account in one tap." : "Reset your Rakni password securely."}
  </div>

  <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color:#1A1A1B;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <table class="wrapper" border="0" cellpadding="0" cellspacing="0" width="520"
          style="background-color:#111112;border-radius:24px;border:1px solid rgba(255,255,255,0.08);overflow:hidden;box-shadow:0 32px 64px rgba(0,0,0,0.6);">

          <tr>
            <td style="background:linear-gradient(90deg,#BDE500 0%,#8fb800 100%);height:3px;font-size:0;line-height:0;">&nbsp;</td>
          </tr>

          <tr>
            <td align="center" style="padding:44px 48px 28px 48px;">
              <div style="width:174px;height:auto;display:inline-block;text-align:center;margin-bottom:18px;">
                <img src="https://rakni-v2.web.app/rakni_logo_white.png" alt="Rakni" width="174" height="52" style="display:block;width:174px;max-width:174px;height:auto;border:0;outline:none;text-decoration:none;"/>
              </div>
              <div style="font-size:13px;color:rgba(255,255,255,0.35);">Smart Parking</div>
            </td>
          </tr>

          <tr>
            <td style="padding:0 48px;">
              <div style="height:1px;background:rgba(255,255,255,0.06);font-size:0;line-height:0;">&nbsp;</div>
            </td>
          </tr>

          <tr>
            <td class="content-pad" style="padding:38px 48px;">
              <h1 style="margin:0 0 12px 0;font-size:24px;font-weight:700;color:#FFFFFF;letter-spacing:-0.4px;text-align:center;">${title}</h1>
              <p style="margin:0 0 28px 0;font-size:15px;color:rgba(255,255,255,0.6);line-height:1.7;text-align:center;">${subTitle}</p>

              <table border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="center" style="padding-bottom:20px;">
                    <a href="${safeActionUrl}" style="background:#BDE500;color:#101010;text-decoration:none;padding:14px 28px;border-radius:999px;font-weight:700;display:inline-block;">
                      ${cta}
                    </a>
                  </td>
                </tr>
              </table>


            </td>
          </tr>

          <tr>
            <td align="center" style="padding:26px 48px 38px;background-color:rgba(0,0,0,0.25);border-top:1px solid rgba(255,255,255,0.05);">
              <p style="margin:0;font-size:11px;color:rgba(255,255,255,0.3);line-height:1.6;">
                If you did not request this, you can safely ignore this email.
              </p>
            </td>
          </tr>
        </table>

      </td>
    </tr>
  </table>

</body>
</html>`;
}

// ---------------------------------------------------------------------------
// Shared Resend send helpers
// ---------------------------------------------------------------------------

async function sendOtpEmail(
  toEmail: string,
  otp: string,
  type: "verification" | "password_reset"
): Promise<void> {
  const resend = getResendClient();
  const isVerification = type === "verification";

  const { error } = await resend.emails.send({
    from: `${RESEND_FROM_NAME} <${RESEND_FROM_EMAIL}>`,
    to: [toEmail],
    subject: isVerification
      ? `Your Rakni verification code: ${otp}`
      : `Your Rakni password reset code: ${otp}`,
    html: buildEmailHtml(otp, type),
    text: isVerification
      ? `Your Rakni verification code is: ${otp}\n\nEnter this code in the app to verify your account. It expires in 10 minutes.\n\nIf you didn't request this, ignore this email.`
      : `Your Rakni password reset code is: ${otp}\n\nUse this code to reset your password. It expires in 10 minutes.\n\nIf you didn't request this, ignore this email.`,
  });

  if (error) {
    console.error("[Resend] sendOtpEmail error:", JSON.stringify(error));
    throw new Error(`Resend error: ${error.message}`);
  }
}

async function sendActionEmail(
  toEmail: string,
  actionUrl: string,
  type: "verification" | "password_reset"
): Promise<void> {
  const resend = getResendClient();
  const isVerification = type === "verification";
  const subject = isVerification
    ? "Verify your Rakni account"
    : "Reset your Rakni password";

  const { error } = await resend.emails.send({
    from: `${RESEND_FROM_NAME} <${RESEND_FROM_EMAIL}>`,
    to: [toEmail],
    subject,
    html: buildActionEmailHtml(actionUrl, type),
    text: `${subject}\n\nOpen this link: ${actionUrl}\n\nIf you did not request this, you can ignore this email.`,
  });

  if (error) {
    console.error("[Resend] sendActionEmail error:", JSON.stringify(error));
    throw new Error(`Resend error: ${error.message}`);
  }
}

// ===========================================================================
// FUNCTION 1 — sendVerificationOTP
// ===========================================================================

export const sendVerificationOTP = functions
  .region("europe-west1")
  .runWith({ secrets: ["RESEND_API_KEY"] })
  .https.onCall(async (data: { email: string; uid: string }) => {
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

    console.log(`[OTP] Verification for ${email}: ${code}`);

    try {
      await sendOtpEmail(email, code, "verification");
    } catch (error) {
      console.error("[Resend] Verification email failed:", error);
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
  .runWith({ secrets: ["RESEND_API_KEY"] })
  .https.onCall(async (data: { email: string }) => {
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

    console.log(`[OTP] Password reset for ${email}: ${code}`);

    try {
      await sendOtpEmail(email, code, "password_reset");
    } catch (error) {
      console.error("[Resend] Password reset email failed:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send password reset email. Please contact support."
      );
    }

    return { success: true };
  });

// ===========================================================================
// FUNCTION 2b — sendVerificationEmailLink
// ===========================================================================

export const sendVerificationEmailLink = functions
  .region("europe-west1")
  .runWith({ secrets: ["RESEND_API_KEY"] })
  .https.onCall(async (data: { email: string; uid?: string }) => {
    const email: string = (data.email ?? "").trim().toLowerCase();
    const uid: string = (data.uid ?? "").trim();

    if (!email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "'email' is required."
      );
    }

    let userRecord: admin.auth.UserRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (error: any) {
      if (error.code === "auth/user-not-found") {
        throw new functions.https.HttpsError(
          "not-found",
          "No account found for this email."
        );
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to validate user account."
      );
    }

    if (uid && userRecord.uid !== uid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Email does not match the signed-in user."
      );
    }

    try {
      const actionCodeSettings: admin.auth.ActionCodeSettings = {
        url: ACTION_HANDLER_BASE_URL,
        handleCodeInApp: false,
      };

      const rawLink = await admin
        .auth()
        .generateEmailVerificationLink(email, actionCodeSettings);
      const actionUrl = buildActionUrl(rawLink, "verifyEmail");

      await sendActionEmail(email, actionUrl, "verification");
      console.log(`[Auth] Verification link sent successfully to ${email}`);
    } catch (error: any) {
      console.error("[Resend] Verification link email failed for email:", email, "error:", error?.message || error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send verification email."
      );
    }

    return { success: true };
  });

// ===========================================================================
// FUNCTION 2c — sendPasswordResetEmailLink
// ===========================================================================

export const sendPasswordResetEmailLink = functions
  .region("europe-west1")
  .runWith({ secrets: ["RESEND_API_KEY"] })
  .https.onCall(async (data: { email: string }) => {
    const email: string = (data.email ?? "").trim().toLowerCase();

    if (!email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "'email' is required."
      );
    }

    try {
      const actionCodeSettings: admin.auth.ActionCodeSettings = {
        url: ACTION_HANDLER_BASE_URL,
        handleCodeInApp: false,
      };

      const rawLink = await admin
        .auth()
        .generatePasswordResetLink(email, actionCodeSettings);
      const actionUrl = buildActionUrl(rawLink, "resetPassword");

      await sendActionEmail(email, actionUrl, "password_reset");
      console.log(`[Auth] Password reset link sent successfully to ${email}`);
    } catch (error: any) {
      if (error.code === "auth/user-not-found") {
        console.log(`[Auth] Password reset requested for non-existent email: ${email}`);
        // Avoid leaking whether the account exists.
        return { success: true };
      }
      console.error("[Resend] Password reset email failed for email:", email, "error:", error?.message || error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send password reset email."
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
    async (data: { email: string; code: string; type: string }) => {
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

      if (record.type !== type) {
        return { success: false, error: "OTP type mismatch." };
      }

      if (record.used === true) {
        return { success: false, error: "This OTP has already been used." };
      }

      const now = admin.firestore.Timestamp.now();
      if (record.expiresAt.toMillis() < now.toMillis()) {
        return {
          success: false,
          error: "This OTP has expired. Please request a new one.",
        };
      }

      if (record.code !== code) {
        return { success: false, error: "Invalid OTP code." };
      }

      if (type === "verification" && record.uid) {
        try {
          await admin.auth().updateUser(record.uid, { emailVerified: true });
          console.log(
            `[OTP] User ${record.uid} (${email}) marked as emailVerified: true`
          );
        } catch (error) {
          console.error("Error updating user verification status:", error);
          throw new functions.https.HttpsError(
            "internal",
            "Failed to verify user account."
          );
        }
      }

      await docRef.update({ used: true });
      console.log(`[OTP] Code for ${email} marked as used.`);

      return { success: true };
    }
  );

// ===========================================================================
// FUNCTION 4 — resetPassword
// ===========================================================================

export const resetPassword = functions
  .region("europe-west1")
  .https.onCall(
    async (data: { email: string; newPassword: string }) => {
      const email: string = (data.email ?? "").trim().toLowerCase();
      const newPassword: string = data.newPassword ?? "";

      if (!email) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "'email' is required."
        );
      }

      if (!newPassword || newPassword.length < 6) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Password must be at least 6 characters."
        );
      }

      const otpDoc = await db.collection("otps").doc(email).get();
      if (!otpDoc.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "No OTP record found. Please request a new password reset code."
        );
      }

      const record = otpDoc.data() as any;

      if (record.type !== "password_reset") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Invalid OTP type for password reset."
        );
      }

      if (record.used !== true) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "OTP has not been verified. Please verify your code first."
        );
      }

      const usedWindowMs = 5 * 60 * 1000;
      const expiresAtMs: number = record.expiresAt.toMillis();
      if (Date.now() > expiresAtMs + usedWindowMs) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Password reset session expired. Please start over."
        );
      }

      try {
        const userRecord = await admin.auth().getUserByEmail(email);
        await admin.auth().updateUser(userRecord.uid, { password: newPassword });
        console.log(
          `[Auth] Password updated for ${email} (uid: ${userRecord.uid})`
        );
      } catch (error: any) {
        console.error("Error resetting password:", error);
        if (error.code === "auth/user-not-found") {
          throw new functions.https.HttpsError(
            "not-found",
            "No account found with this email."
          );
        }
        throw new functions.https.HttpsError(
          "internal",
          "Failed to reset password. Please try again."
        );
      }

      await db.collection("otps").doc(email).delete();
      console.log(
        `[OTP] Deleted OTP record for ${email} after successful password reset.`
      );

      return { success: true };
    }
  );

// ===========================================================================
// FUNCTION 5 — onNotificationCreated (FCM Trigger)
// ===========================================================================

export const onNotificationCreated = functions
  .region("europe-west1")
  .firestore.document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (!data) {
      console.log("[FCM] Notification document is empty. Skipping.");
      return;
    }

    const userId = data.userId;
    const title = data.title;
    const body = data.body;
    const type = data.type ?? "default";

    if (!userId || !title || !body) {
      console.log(`[FCM] Missing userId (${userId}), title (${title}), or body (${body}). Skipping.`);
      return;
    }

    try {
      // Get the user document to retrieve the fcmToken
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.log(`[FCM] User ${userId} not found in Firestore.`);
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`[FCM] No fcmToken registered for user ${userId}.`);
        return;
      }

      // Construct FCM push message payload
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "rakni_channel_id",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send the push notification
      const response = await admin.messaging().send(message);
      console.log(`[FCM] Successfully sent push notification to user ${userId}. Message ID: ${response}`);
    } catch (error) {
      console.error(`[FCM] Error sending push notification to user ${userId}:`, error);
    }
  });

