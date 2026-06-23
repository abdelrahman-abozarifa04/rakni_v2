const { Resend } = require('resend');

// Please replace 're_Jd57FgUs_63pCy17UrRGeU9WyNN3dPrsr' with your real API key
const resend = new Resend('re_Jd57FgUs_63pCy17UrRGeU9WyNN3dPrsr');

resend.emails.send({
  from: 'onboarding@resend.dev',
  to: 'as0144549@gmail.com',
  subject: 'Hello World',
  html: '<p>Congrats on sending your <strong>first email</strong>!</p>'
}).then(response => {
  console.log('Email sent successfully:', response);
}).catch(err => {
  console.error('Failed to send email:', err);
});
