#wiki 
*game entity / character type* 

# Schaap gedrag
Schaap gedrag is complex. To choose an action, they first evaluate which of their basic *[[#behoefte]]* takes priority. For each *behoefte* there is a corresponding logic tree they follow which ends in determining their final *[[#action]]*. [[#Movement]] actions have special logic.

## Behoefte
- [[#Voeding]]
- [[#Ruimte]]
- [[#Gezelligheid]]

## Other behavioural properties
Schapen also keep track of other variables that influence their behaviour indirectly:
- Perceived state of kudde
- Gebroken
- Wolligheid
- Pensvolheid
- Ooi/ram
- Ziektes and symptomen

#### Voeding
The behoefte for *voeding* grows over time and is depleted by [[#Grazen]] and [[#Herkauwen]].

#### Ruimte
The behoefte for *ruimte* grows when annoying entities (such as the [[herder]] or other schapen, depending on their state) approach the sheep, resulting in the sheep engaging in [[#Movement]].

#### Gezelligheid
The behoefte for *gezelligheid* is determined by the amount of familiar schapen in close proximity. A high behoefte for gezelligheid results in [[#Movement]].

## Movement
When schapen start moving their direction is computed based on multiple factors.

## Action
- [[#Grazen]]
- [[#Social behaviour]]
- Being herded; [[herding mechanic]]

### Grazen
To increase their pensvolheid schapen can start *grazen* in a [[grasgebied]]

#### Herkauwen
When a schaap's pensvolheid is high enough they start herkauwen, resulting in their behoefte for voeding depleting.