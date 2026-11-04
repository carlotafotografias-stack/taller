import 'package:firebase_core/firebase_core.dart';

// ============================================================
//  CONFIGURACIÓN DE FIREBASE
//  Datos de la app web registrada en el proyecto "taller"
//  (Firebase › Configuración del proyecto › Tus apps).
//  Estos valores son públicos: los datos quedan protegidos
//  por las reglas de seguridad de Firestore (firebase/firestore.rules).
// ============================================================

const firebaseOptions = FirebaseOptions(
  apiKey: 'TU-API-KEY',
  authDomain: 'TU-PROYECTO.firebaseapp.com',
  projectId: 'TU-PROYECTO',
  storageBucket: 'TU-PROYECTO.firebasestorage.app',
  messagingSenderId: '000000000000',
  appId: '1:000000000000:web:0000000000000000000000',
);
