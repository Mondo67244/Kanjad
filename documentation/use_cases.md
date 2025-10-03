## Diagramme des Cas d'Utilisation

Ce diagramme montre les principales fonctionnalités accessibles par les différents types d'utilisateurs (acteurs) de l'application Kanjad.

```plantuml
@startuml
!theme vibrant
title Cas d'Utilisation - Kanjad

left to right direction

actor Visiteur
actor Client extends Visiteur
actor Administrateur
actor Commercial
actor Livreur

rectangle Kanjad {
  ' Use cases pour Visiteur
  usecase "Consulter les produits" as UC1
  usecase "Rechercher un produit" as UC2
  usecase "S'inscrire" as UC3
  usecase "Se connecter" as UC4

  ' Use cases pour Client (hérite de Visiteur)
  usecase "Ajouter au panier" as UC5
  usecase "Ajouter aux souhaits" as UC6
  usecase "Passer une commande" as UC7
  usecase "Gérer son profil" as UC8
  usecase "Voir ses commandes" as UC9
  usecase "Discuter avec un vendeur" as UC10
  usecase "Voir ses factures" as UC11

  ' Use cases pour Administrateur
  usecase "Gérer les produits (CRUD)" as UC_A1
  usecase "Gérer les utilisateurs" as UC_A2
  usecase "Gérer les commandes" as UC_A3
  usecase "Gérer les promotions" as UC_A4
  usecase "Voir les statistiques" as UC_A5
  usecase "Gérer les stocks" as UC_A6

  ' Use cases pour Commercial
  usecase "Gérer les discussions" as UC_C1

  ' Use cases pour Livreur
  usecase "Voir les livraisons" as UC_L1
  usecase "Mettre à jour statut livraison" as UC_L2
}

' Liaisons Visiteur
Visiteur --> UC1
Visiteur --> UC2
Visiteur --> UC3
Visiteur --> UC4

' Liaisons Client
Client --> UC5
Client --> UC6
Client --> UC7
Client --> UC8
Client --> UC9
Client --> UC10
Client --> UC11

' Liaisons Administrateur
Administrateur --> UC_A1
Administrateur --> UC_A2
Administrateur --> UC_A3
Administrateur --> UC_A4
Administrateur --> UC_A5
Administrateur --> UC_A6

' Liaisons Commercial
Commercial --> UC_C1

' Liaisons Livreur
Livreur --> UC_L1
Livreur --> UC_L2

@enduml
```
