/// Taille d'une tuile en pixels monde (= pixels des sprites Kenney).
const double kTile = 18.0;

/// Facteur d'échelle par rapport au réglage d'origine (tuiles de 32 px) :
/// les vitesses, gravités et tailles du gameplay sont exprimées en
/// « unités 32 px » puis multipliées par ce facteur.
const double kScale = kTile / 32;

/// Résolution fixe de la caméra (16:9, x4 = 1080p).
const double kViewWidth = 480.0;
const double kViewHeight = 270.0;
