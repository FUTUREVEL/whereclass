// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getFirestore } from "firebase/firestore"; // 이 줄 추가
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyAJa0OimjMiuxlg3Nt6r_E_RjN9KgET4nw",
  authDomain: "where-s-d-class.firebaseapp.com",
  projectId: "where-s-d-class",
  storageBucket: "where-s-d-class.firebasestorage.app",
  messagingSenderId: "618518853469",
  appId: "1:618518853469:web:d7ac3f1cf66fb5f9485ab4",
  measurementId: "G-C6QG6SWEX1"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const db = getFirestore(app); // 이 줄 추가

export { db }; // db export 추가