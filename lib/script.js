const admin = require('firebase-admin');
const serviceAccount = require('./service_key/service_account_keys.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const firestore = admin.firestore();

const jsonData = {
  formId: "contactForm",
  fields: [
    { label: "Name", type: "text", required: true },
    { label: "Email", type: "email", required: true },
    { label: "Message", type: "textarea", required: false }
  ]
};

async function uploadJsonData() {
  const res = await firestore.collection('forms').doc(jsonData.formId).set(jsonData);
  console.log('Document successfully written!');
}

uploadJsonData().catch(console.error);