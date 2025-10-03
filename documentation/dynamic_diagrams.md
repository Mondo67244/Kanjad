## Diagrammes de Séquence et d'Activité

### Analyse des Concepts POO

- **Encapsulation :** Chaque classe de données (ex: `Produit`, `Commande`) regroupe ses attributs et les méthodes pour les manipuler (`toMap`, `fromMap`). Les services (ex: `SupabaseService`, `AuthService`) encapsulent la logique métier et l'accès à la base de données, masquant la complexité interne.

- **Héritage :** Votre projet utilise principalement l'héritage fourni par le framework Flutter (`StatefulWidget`, `StatelessWidget`). Il n'y a pas de hiérarchie d'héritage complexe dans vos modèles de données, ce qui favorise la composition, une approche moderne et flexible.

- **Polymorphisme :** Le polymorphisme est visible dans la gestion des rôles. Par exemple, la fonction `navigateBasedOnRole` redirige l'utilisateur vers des écrans différents (`Accueila`, `Accueilu`, `AccueilLivreur`) en fonction de la valeur de `Utilisateur.roleutilisateur`. C'est une forme de polymorphisme qui adapte le comportement de l'application au type de l'objet `Utilisateur`.

### Diagramme de Séquence : Connexion d'un Utilisateur

```plantuml
@startuml
!theme vibrant
actor User
participant "PageConnexion (UI)" as UI
participant "AuthService" as Auth
participant "SupabaseClient" as Supabase
participant "SupabaseService" as DbService
participant "Redirigeur" as Nav

User -> UI: Remplit email & mot de passe
User -> UI: Clique sur "Se connecter"
activate UI

UI -> Auth: signInWithEmailAndPassword()
activate Auth

Auth -> Supabase: auth.signInWithPassword()
activate Supabase
Supabase --> Auth: AuthResponse (succès)
deactivate Supabase

Auth --> UI: AuthResponse
deactivate Auth

UI -> DbService: getUtilisateur(userId)
activate DbService
DbService -> Supabase: from('utilisateurs').select().eq()
activate Supabase
Supabase --> DbService: Données Utilisateur
deactivate Supabase
DbService --> UI: Objet Utilisateur
deactivate DbService

UI -> Nav: navigateBasedOnRole(user)
activate Nav
Nav -> UI: Redirige vers l'écran approprié
deactivate Nav

deactivate UI
@enduml
```

### Diagramme d'Activité : Processus de Commande Client

```plantuml
@startuml
!theme vibrant
title Processus de Commande

start
:Le client ajoute des produits au panier;

if (Panier non vide ?) then (oui)
  :Le client va sur la page Panier;
  :Vérifie le récapitulatif;
  :Choisit la méthode de livraison;
  :Choisit la méthode de paiement;
  :Confirme les conditions;
  :Clique sur "Créer la commande";

  if (Utilisateur connecté ?) then (oui)
    :Crée un objet Commande;
    :Sauvegarde la commande dans Supabase;
    note right: SupabaseService.addCommande()
    :Vide le panier local;
    :Affiche une confirmation de succès;
    stop
  else (non)
    :Affiche une popup de connexion;
    :Redirige vers la page de connexion;
    stop
  endif

else (non)
  :Reste sur la page des produits;
  stop
endif

@enduml
```
