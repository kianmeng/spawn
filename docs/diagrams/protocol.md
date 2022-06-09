# Spawn Protocol

## Registering Actors in an Actor System

```
+----------------+                                     +---------------------+                                     +-------+                   
| User Function  |                                     | Local Spawn Sidecar |                                     | Actor |                   
+----------------+                                     +---------------------+                                     +-------+                   
        |                                                       |                                                     |                       
        | HTTP POST Registration Request                        |                                                     |                       
        |------------------------------------------------------>|                                                     |                       
        |                                                       |                                                     |                       
        |                                                       | Upfront start Actors with BEAM Distributed Protocol |                       
        |                                                       |---------------------------------------------------->|
        |                                                       |                                                     |                       
        |                                                       |                                                     |Initialize Statestore 
        |                                                       |                                                     |---------------------- 
        |                                                       |                                                     |                     | 
        |                                                       |                                                     |<--------------------- 
        |                                                       |                                                     |                       
        |          HTTP Registration Response                   |                                                     |                       
        |<------------------------------------------------------|                                                     |                       
        |                                                       |                                                     | 

```

## Calling Actors:

```
+-----------------+                       +------------------------+       +------------------------+                                         +--------------------------------+
| User Function A |                       | Local Spawn Sidecar A  |       | Remote User Function B |                                         | Remote Spawn Sidecar / Actor B |
+-----------------+                       +------------------------+       +------------------------+                                         +--------------------------------+
        |                                             |                                |                                                                     |
        | HTTP POST Invocation Request.               |                                |                                                                     |
        |-------------------------------------------->|                                |                                                                     |
        |                                             |                                |                                                                     |
        |                                             | Lookup for Actor               |                                                                     |
        |                                             |-----------------               |                                                                     |
        |                                             |                |               |                                                                     |
        |                                             |<----------------               |                                                                     |
        |                                             |                                |                                                                     |
        |                                             | Make a BEAM Distributed Protocol Call on Actor located at proxy b                                    |
        |                                             |----------------------------------------------------------------------------------------------------->|
        |                                             |                                |                                                                     |
        |                                             |                                |                        Make HTTP POST in /api/v1/actors/actions     |
        |                                             |                                |<--------------------------------------------------------------------|
        |                                             |                                |                                                                     |
        |                                             |                                | Handle request, execute command                                     |
        |                                             |                                |--------------------------------                                     |
        |                                             |                                |                               |                                     |
        |                                             |                                |<-------------------------------                                     |
        |                                             |                                |                                                                     |
        |                                             |                                | HTTP Reply with the result and the new state of actor B             |
        |                                             |                                |-------------------------------------------------------------------->|
        |                                             |                                |                                                                     |
        |                                             |                 Receive response, store new state, and return result value to original caller        |
        |                                             |<-----------------------------------------------------------------------------------------------------|
        |                                             |                                |                                                                     |
        |              Respond to user                |                                |                                                                     |
        |<--------------------------------------------|                                |                                                                     |
        |                                             |                                |                                                                     |
```        