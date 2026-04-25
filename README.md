# App Duralon

Aplicacion Flutter para catalogo y compra mayorista de articulos plasticos, con integracion Firebase para autenticacion, reglas comerciales por producto y lectura en tiempo real.

## Estado actual del proyecto

- Registro e inicio de sesion con Firebase Auth (email/password)
- Registro empresarial mayorista con:
  - RNC
  - tipo de contribuyente
  - razon social, contacto, telefono y direccion fiscal
- Validacion de RNC dominicano y control de RNC duplicado
- Reglas mayoristas por producto:
  - cantidad minima (`minOrderQty`)
  - multiplo de compra (`stepQty`)
- Modo invitado de solo lectura con catalogo en tiempo real desde Firestore
- Pantalla interna para administrar reglas mayoristas (solo roles internos)

## Tecnologias principales

- Flutter (Dart)
- Firebase Core
- Firebase Authentication
- Cloud Firestore

## Estructura funcional relevante

- `lib/main.dart`: inicializacion de Firebase y arranque de la app
- `lib/pages/login_screen.dart`: pantalla de acceso principal
- `lib/pages/iniciar_session_screen.dart`: login real con Firebase Auth
- `lib/pages/crear_cuenta_screen.dart`: registro mayorista con datos fiscales/comerciales
- `lib/pages/home_screen.dart`: home, menu y flujo invitado/usuario
- `lib/pages/producto_screen.dart`: detalle de producto con validacion de minimo/multiplo
- `lib/pages/admin_wholesale_rules_screen.dart`: gestion admin de reglas mayoristas
- `lib/services/auth_service.dart`: servicio de autenticacion y registro en Firestore
- `lib/services/product_rules_service.dart`: lectura de reglas por producto desde Firestore
- `firestore.rules`: reglas de seguridad de Firestore

## Roles usados en el sistema

- `owner`: propietario del cliente
- `buyer`: comprador del cliente
- `accounting`: usuario contable del cliente (reservado para fases siguientes)
- `sales_admin`: rol interno comercial
- `admin`: rol interno con control operativo

En la implementacion actual, la gestion de reglas mayoristas esta pensada para `admin` y `sales_admin`.

## Modelo de datos esperado en Firestore

### Coleccion `users/{uid}`

Campos usados en permisos y sesion:

- `uid`
- `customerId`
- `email`
- `role` (ej: `owner`, `admin`, `sales_admin`)
- `status`

### Coleccion `customers/{customerId}`

Campos principales:

- `rnc`
- `rncNormalized`
- `taxpayerType`
- `legalName`
- `contactName`
- `phone`
- `billingEmail`
- `fiscalAddress`
- `status`
- `creditEnabled`

### Coleccion `products/{productId}`

Campos minimos recomendados para catalogo en tiempo real:

- `name` (string)
- `category` (string)
- `price` (number)

Campos mayoristas recomendados:

- `minOrderQty` (int)
- `stepQty` (int)

Campos opcionales:

- `listPrice` (number)
- `imageAsset` (string de asset local)

## Requisitos

- Flutter SDK instalado
- Cuenta/proyecto de Firebase configurado
- Firebase CLI instalada

## Configuracion local

1. Instalar dependencias:

```bash
flutter pub get
```

2. Verificar `firebase_options.dart` generado para Android/iOS.

3. Activar en Firebase Console:

- Authentication > Email/Password
- Firestore Database

4. Publicar reglas de Firestore:

```bash
firebase deploy --only firestore:rules
```

### Nota para Windows + PowerShell

Si PowerShell bloquea `firebase.ps1`, usar:

```bash
firebase.cmd deploy --only firestore:rules
```

o

```bash
npx firebase-tools deploy --only firestore:rules
```

## Ejecutar la app

```bash
flutter run
```

## Flujo de prueba recomendado

1. Entrar como invitado y confirmar catalogo en tiempo real (solo lectura)
2. Registrar una cuenta nueva y validar creacion en Auth + Firestore
3. Iniciar sesion con la cuenta creada
4. Probar reglas mayoristas en detalle de producto (minimo/multiplo)
5. Si el usuario tiene rol `admin` o `sales_admin`, abrir y usar "Reglas mayoristas"

## Observaciones

- El proyecto mantiene datos mock como respaldo para algunos listados.
- La compra completa, facturacion y cuentas por cobrar pueden ampliarse en fases siguientes.
