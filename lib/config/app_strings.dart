import 'package:app_duralon/services/locale_service.dart';

// ignore_for_file: non_constant_identifier_names
abstract final class S {
  static AppLanguage get _lang => LocaleService.instance.language;

  static String _t({required String es, required String en, required String fr}) =>
      switch (_lang) {
        AppLanguage.es => es,
        AppLanguage.en => en,
        AppLanguage.fr => fr,
      };

  // ── Login ────────────────────────────────────────────────────────────────────
  static String get welcome       => _t(es: '¡Bienvenido!',          en: 'Welcome!',               fr: 'Bienvenue !');
  static String get rncLabel      => _t(es: 'RNC o Cédula',          en: 'RNC or ID',              fr: 'RNC ou ID fiscal');
  static String get rncHint       => _t(es: 'Ej: 123456789',         en: 'e.g. 123456789',         fr: 'Ex: 123456789');
  static String get rncEmpty      => _t(es: 'Ingresa tu RNC',        en: 'Enter your RNC',         fr: 'Entrez votre RNC');
  static String get passwordLabel => _t(es: 'Contraseña',            en: 'Password',               fr: 'Mot de passe');
  static String get passwordEmpty => _t(es: 'Ingresa tu contraseña', en: 'Enter your password',    fr: 'Entrez votre mot de passe');
  static String get loginBtn      => _t(es: 'Ingresar',              en: 'Log in',                 fr: 'Se connecter');
  static String get browseGuest   => _t(es: 'Echar un vistazo como invitado', en: 'Browse as guest', fr: "Parcourir en tant qu'invité");
  static String get continueGuest => _t(es: 'Continuar como invitado', en: 'Continue as guest',    fr: "Continuer en tant qu'invité");

  // ── Auth errors ──────────────────────────────────────────────────────────────
  static String get errInactive   => _t(es: 'Tu cuenta está inactiva. Contacta al administrador.', en: 'Your account is inactive. Contact the administrator.', fr: "Votre compte est inactif. Contactez l'administrateur.");
  static String get errNotFound   => _t(es: 'No existe una cuenta con ese RNC.', en: 'No account found with that RNC.', fr: 'Aucun compte trouvé avec ce RNC.');
  static String get errWrongPass  => _t(es: 'Contraseña incorrecta.',  en: 'Incorrect password.',        fr: 'Mot de passe incorrect.');
  static String get errBadCred    => _t(es: 'RNC o contraseña incorrectos.', en: 'Incorrect RNC or password.', fr: 'RNC ou mot de passe incorrect.');
  static String get errTooMany    => _t(es: 'Demasiados intentos. Espera un momento.', en: 'Too many attempts. Please wait.', fr: 'Trop de tentatives. Veuillez patienter.');
  static String get errGeneric    => _t(es: 'No se pudo iniciar sesión. Intenta de nuevo.', en: 'Could not sign in. Please try again.', fr: 'Impossible de se connecter. Réessayez.');

  // ── Header ───────────────────────────────────────────────────────────────────
  static String get searchHint    => _t(es: 'Buscar productos',      en: 'Search products',        fr: 'Rechercher des produits');
  static String get cartTooltip   => _t(es: 'Carrito',               en: 'Cart',                   fr: 'Panier');
  static String get menuTooltip   => _t(es: 'Menú',                  en: 'Menu',                   fr: 'Menu');

  // ── Menú lateral ─────────────────────────────────────────────────────────────
  static String get menuHome      => _t(es: 'Inicio',                en: 'Home',                   fr: 'Accueil');
  static String get menuCatalog   => _t(es: 'Catálogo',              en: 'Catalogue',              fr: 'Catalogue');
  static String get menuProfile   => _t(es: 'Mi perfil',             en: 'My Profile',             fr: 'Mon profil');
  static String get menuOffers    => _t(es: 'Ofertas',               en: 'Offers',                 fr: 'Offres');
  static String get menuOrders    => _t(es: 'Mis pedidos',           en: 'My Orders',              fr: 'Mes commandes');
  static String get menuAddresses => _t(es: 'Mis direcciones',       en: 'My Addresses',           fr: 'Mes adresses');
  static String get menuPayments  => _t(es: 'Métodos de pago',       en: 'Payment Methods',        fr: 'Modes de paiement');
  static String get menuSupport   => _t(es: 'Soporte',               en: 'Support',                fr: 'Assistance');
  static String get menuWholesale => _t(es: 'Reglas mayoristas',     en: 'Wholesale Rules',        fr: 'Règles de gros');
  static String get menuAdmin     => _t(es: 'Panel de administración', en: 'Admin Panel',          fr: "Panneau d'administration");
  static String get menuLogout    => _t(es: 'Cerrar sesión',         en: 'Log out',                fr: 'Se déconnecter');
  static String get menuLogin     => _t(es: 'Iniciar sesión',        en: 'Log in',                 fr: 'Se connecter');
  static String get menuTerms     => _t(es: 'Términos y condiciones', en: 'Terms & Conditions',    fr: 'Conditions générales');
  static String get menuAbout     => _t(es: 'Quiénes somos',         en: 'About us',               fr: 'Qui sommes-nous');
  static String get guestMode     => _t(es: 'Modo invitado',         en: 'Guest mode',             fr: 'Mode invité');

  // ── Roles ─────────────────────────────────────────────────────────────────────
  static String get roleRetail    => _t(es: 'Cliente Minorista',     en: 'Retail Customer',        fr: 'Client de détail');
  static String get roleDistrib   => _t(es: 'Cliente Distribuidor',  en: 'Distributor',            fr: 'Distributeur');
  static String get roleClient    => _t(es: 'Cliente',               en: 'Customer',               fr: 'Client');
  static String get roleAdmin     => _t(es: 'Administrador',         en: 'Administrator',          fr: 'Administrateur');
  static String get roleSeller    => _t(es: 'Vendedor',              en: 'Sales Rep',              fr: 'Vendeur');

  // ── Catálogo ──────────────────────────────────────────────────────────────────
  static String get tabHome       => _t(es: 'HOGAR',                 en: 'HOME',                   fr: 'MAISON');
  static String get tabIndustrial => _t(es: 'INDUSTRIAL',            en: 'INDUSTRIAL',             fr: 'INDUSTRIEL');
  static String get catalogTitle  => _t(es: 'Catálogo',              en: 'Catalogue',              fr: 'Catalogue');
  static String get filterHint    => _t(es: 'Filtrar por nombre de sección...', en: 'Filter by section name...', fr: 'Filtrer par section...');
  static String get allCategories => _t(es: 'TODAS LAS CATEGORÍAS',  en: 'ALL CATEGORIES',         fr: 'TOUTES LES CATÉGORIES');
  static String get viewAll       => _t(es: 'Ver todos',             en: 'View all',               fr: 'Voir tout');
  static String get noCategories  => _t(es: 'No hay categorías disponibles.\nUn administrador debe cargarlas desde el Panel.', en: 'No categories available.\nAn administrator must load them from the Panel.', fr: "Aucune catégorie disponible.\nUn administrateur doit les charger depuis le Panneau.");
  static String get noProducts    => _t(es: 'No se encontraron productos con esa búsqueda.', en: 'No products found for that search.', fr: 'Aucun produit trouvé pour cette recherche.');
  static String get resultsFor    => _t(es: 'Resultados para',       en: 'Results for',            fr: 'Résultats pour');
  static String get comingSoon    => _t(es: 'Próximamente disponible.', en: 'Coming soon.',         fr: 'Bientôt disponible.');

  // ── Características (etiquetas técnicas) ─────────────────────────────────────
  static String get codeLabel    => _t(es: 'Código',        en: 'Code',             fr: 'Code');
  static String get eanLabel     => _t(es: 'EAN',           en: 'EAN',              fr: 'EAN');
  static String get lengthLabel  => _t(es: 'Largo',         en: 'Length',           fr: 'Longueur');
  static String get widthLabel   => _t(es: 'Ancho',         en: 'Width',            fr: 'Largeur');
  static String get heightLabel  => _t(es: 'Alto',          en: 'Height',           fr: 'Hauteur');
  static String get weightLabel  => _t(es: 'Peso',          en: 'Weight',           fr: 'Poids');
  static String get cbmPerPack   => _t(es: 'CBM / empaque', en: 'CBM / pack',       fr: 'CBM / emballage');
  static String get packLabel    => _t(es: 'Empaque',       en: 'Pack',             fr: 'Emballage');
  static String get totalPallet  => _t(es: 'Total/Pallet',  en: 'Total/Pallet',     fr: 'Total/Palette');

  // ── Pantalla de producto ──────────────────────────────────────────────────────
  static String get productTitle  => _t(es: 'Producto',              en: 'Product',                fr: 'Produit');
  static String get addToCart     => _t(es: 'Añadir al carrito',     en: 'Add to cart',            fr: 'Ajouter au panier');
  static String get addToList     => _t(es: 'Lista',                 en: 'List',                   fr: 'Liste');
  static String get favorites     => _t(es: 'Favoritos',             en: 'Favorites',              fr: 'Favoris');
  static String get share         => _t(es: 'Compartir',             en: 'Share',                  fr: 'Partager');
  static String get priceConsult  => _t(es: 'Precio a consultar',    en: 'Price on request',       fr: 'Prix sur demande');
  static String get minPurchase   => _t(es: 'Compra mínima',         en: 'Minimum order',          fr: 'Commande minimale');
  static String get multiple      => _t(es: 'Múltiplo',              en: 'Multiple',               fr: 'Multiple');
  static String get packages      => _t(es: 'Empaques',              en: 'Packages',               fr: 'Emballages');
  static String get package       => _t(es: 'empaque',               en: 'package',                fr: 'emballage');
  static String get packagePlural => _t(es: 'empaques',              en: 'packages',               fr: 'emballages');
  static String get units         => _t(es: 'unidades',              en: 'units',                  fr: 'unités');
  static String get total         => _t(es: 'Total',                 en: 'Total',                  fr: 'Total');
  static String get characteristics => _t(es: 'Características',    en: 'Specifications',         fr: 'Caractéristiques');
  static String get colorLabel    => _t(es: 'Color',                 en: 'Color',                  fr: 'Couleur');
  static String get surtido       => _t(es: 'Surtido',               en: 'Assorted',               fr: 'Assorti');
  static String get colorNotSelectable => _t(es: '(color no seleccionable)', en: '(color not selectable)', fr: '(couleur non sélectionnable)');
  static String get priceRetail   => _t(es: 'Precio minorista',      en: 'Retail price',           fr: 'Prix de détail');
  static String get priceDistrib  => _t(es: 'Precio distribuidor',   en: 'Distributor price',      fr: 'Prix distributeur');
  static String get yourPrice     => _t(es: 'Tu precio',             en: 'Your price',             fr: 'Votre prix');
  static String get price         => _t(es: 'Precio',                en: 'Price',                  fr: 'Prix');
  static String get stock         => _t(es: 'Stock',                 en: 'Stock',                  fr: 'Stock');
  static String get boxes         => _t(es: 'cajas',                 en: 'boxes',                  fr: 'boîtes');
  static String get loginToSeePrices => _t(es: 'Precio disponible para clientes registrados', en: 'Price available for registered customers', fr: 'Prix disponible pour les clients enregistrés');
  static String get loginToAddCart   => _t(es: 'Inicia sesión para ver tu precio especial y agregar al carrito.', en: 'Log in to see your special price and add to cart.', fr: 'Connectez-vous pour voir votre prix spécial et ajouter au panier.');
  static String get signIn        => _t(es: 'Iniciar sesión',        en: 'Sign in',                fr: 'Se connecter');
  static String get closePhoto    => _t(es: 'Cerrar',                en: 'Close',                  fr: 'Fermer');
  static String get minQtyError   => _t(es: 'Cantidad mínima',       en: 'Minimum quantity',       fr: 'Quantité minimale');
  static String get multipleError => _t(es: 'Compra en múltiplos de', en: 'Buy in multiples of',  fr: 'Achetez par multiples de');
  static String get from          => _t(es: 'desde',                 en: 'from',                   fr: 'depuis');

  // ── Carrito ───────────────────────────────────────────────────────────────────
  static String get cart          => _t(es: 'Mi pedido',             en: 'My Order',               fr: 'Ma commande');
  static String get cartEmpty     => _t(es: 'Tu carrito está vacío', en: 'Your cart is empty',     fr: 'Votre panier est vide');
  static String get cartEmptySub  => _t(es: 'Agrega productos desde el catálogo', en: 'Add products from the catalogue', fr: 'Ajoutez des produits depuis le catalogue');
  static String get viewCatalog   => _t(es: 'Ver catálogo',          en: 'View catalogue',         fr: 'Voir le catalogue');
  static String get confirmOrder  => _t(es: 'Confirmar pedido',      en: 'Confirm order',          fr: 'Confirmer la commande');
  static String get confirmOrderBtn => _t(es: 'Confirmar pedido →',  en: 'Confirm order →',        fr: 'Confirmer →');
  static String get cancel        => _t(es: 'Cancelar',              en: 'Cancel',                 fr: 'Annuler');
  static String get deliveryNotes => _t(es: 'Notas de entrega (opcional)', en: 'Delivery notes (optional)', fr: 'Notes de livraison (optionnel)');
  static String get products      => _t(es: 'PRODUCTOS',             en: 'PRODUCTS',               fr: 'PRODUITS');
  static String get customer      => _t(es: 'Cliente',               en: 'Customer',               fr: 'Client');
  static String get orderError    => _t(es: 'Error al confirmar pedido', en: 'Error confirming order', fr: 'Erreur lors de la commande');

  // ── Mis pedidos ───────────────────────────────────────────────────────────────
  static String get myOrders      => _t(es: 'Mis pedidos',           en: 'My Orders',              fr: 'Mes commandes');
  static String get ordersEmpty   => _t(es: 'No tienes pedidos aún', en: 'No orders yet',          fr: 'Aucune commande pour l\'instant');
  static String get ordersEmptySub=> _t(es: 'Tus órdenes aparecerán aquí', en: 'Your orders will appear here', fr: 'Vos commandes apparaîtront ici');
  static String get ordersError   => _t(es: 'Error al cargar pedidos', en: 'Error loading orders', fr: 'Erreur de chargement');
  static String get order         => _t(es: 'Pedido',                en: 'Order',                  fr: 'Commande');
  static String get date          => _t(es: 'Fecha',                 en: 'Date',                   fr: 'Date');
  static String get notes         => _t(es: 'Notas',                 en: 'Notes',                  fr: 'Notes');
  static String get itbis         => _t(es: 'ITBIS 18%',             en: 'Tax 18%',                fr: 'Taxe 18%');

  // ── Ofertas ───────────────────────────────────────────────────────────────────
  static String get offers        => _t(es: 'Ofertas',               en: 'Offers',                 fr: 'Offres');
  static String get offersEmpty   => _t(es: 'No hay ofertas disponibles', en: 'No offers available', fr: 'Aucune offre disponible');
  static String get offersEmptySub=> _t(es: 'Pronto publicaremos promociones especiales', en: 'We will publish special promotions soon', fr: 'Nous publierons bientôt des promotions spéciales');
  static String get add           => _t(es: 'Agregar',               en: 'Add',                    fr: 'Ajouter');

  // ── Perfil ────────────────────────────────────────────────────────────────────
  static String get myProfile     => _t(es: 'Mi perfil',             en: 'My Profile',             fr: 'Mon profil');
  static String get noSession     => _t(es: 'No hay sesión activa.', en: 'No active session.',      fr: 'Aucune session active.');
  static String get retry         => _t(es: 'Reintentar',            en: 'Retry',                  fr: 'Réessayer');
  static String get accountInfo   => _t(es: 'Información de cuenta', en: 'Account Information',    fr: 'Informations du compte');
  static String get clientInfo    => _t(es: 'Información de cliente', en: 'Client Information',    fr: 'Informations client');
  static String get name          => _t(es: 'Nombre',                en: 'Name',                   fr: 'Nom');
  static String get email         => _t(es: 'Correo',                en: 'Email',                  fr: 'E-mail');
  static String get memberSince   => _t(es: 'Miembro desde',         en: 'Member since',           fr: 'Membre depuis');
  static String get role          => _t(es: 'Rol',                   en: 'Role',                   fr: 'Rôle');
  static String get status        => _t(es: 'Estado',                en: 'Status',                 fr: 'Statut');
  static String get provider      => _t(es: 'Proveedor',             en: 'Provider',               fr: 'Fournisseur');
  static String get userId        => _t(es: 'ID de usuario',         en: 'User ID',                fr: 'ID utilisateur');
  static String get clientType    => _t(es: 'Tipo de cliente',       en: 'Client type',            fr: 'Type de client');
  static String get fiscalAddress => _t(es: 'Dirección fiscal',      en: 'Fiscal address',         fr: 'Adresse fiscale');
  static String get creditEnabled => _t(es: 'Crédito habilitado',    en: 'Credit enabled',         fr: 'Crédit activé');
  static String get registered    => _t(es: 'Registrado',            en: 'Registered',             fr: 'Inscrit');
  static String get statusActive  => _t(es: 'Activo',                en: 'Active',                 fr: 'Actif');
  static String get statusPending => _t(es: 'Pendiente validación',  en: 'Pending validation',     fr: 'En attente de validation');
  static String get statusSuspended => _t(es: 'Suspendido',          en: 'Suspended',              fr: 'Suspendu');
  static String get yes           => _t(es: 'Sí',                    en: 'Yes',                    fr: 'Oui');
  static String get no            => _t(es: 'No',                    en: 'No',                     fr: 'Non');
  static String get taxpayerCompany => _t(es: 'Empresa',             en: 'Company',                fr: 'Entreprise');
  static String get taxpayerFreeZone => _t(es: 'Zona Franca',        en: 'Free Zone',              fr: 'Zone Franche');
  static String get taxpayerGov   => _t(es: 'Gubernamental',         en: 'Government',             fr: 'Gouvernemental');
  static String get taxpayerPerson => _t(es: 'Persona Física',       en: 'Individual',             fr: 'Particulier');
  static String get loginProvider => _t(es: 'Correo y contraseña',   en: 'Email and password',     fr: 'E-mail et mot de passe');
  static String get loadError     => _t(es: 'No se pudieron cargar los datos.', en: 'Could not load data.', fr: 'Impossible de charger les données.');
}
