const admin = require('firebase-admin');
let firebaseInitialized = false;

function initializeFirebase() {
  if (firebaseInitialized) return;
  try {
    if (process.env.FIREBASE_PROJECT_ID) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        }),
      });
      console.log('✅ Firebase Admin initialized');
    } else {
      console.log('⚠️  Firebase Admin not configured — dev mode active');
    }
  } catch (e) {
    console.log('⚠️  Firebase Admin init failed — dev mode active:', e.message);
  }
  firebaseInitialized = true;
}
initializeFirebase();

async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  const idToken = authHeader.split('Bearer ')[1];

  try {
    if (admin.apps.length > 0) {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      req.userId = decodedToken.uid;
      req.userEmail = decodedToken.email;
      return next();
    }

    // Firebase not configured — only allow the x-user-id fallback in
    // non-production environments. In production we hard-fail.
    if (process.env.NODE_ENV === 'production') {
      return res.status(401).json({ error: 'Auth backend not configured' });
    }
    req.userId = req.headers['x-user-id'] || 'dev-user';
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

module.exports = { verifyFirebaseToken };
