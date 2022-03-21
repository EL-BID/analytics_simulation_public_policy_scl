**SCL Data - Data Ecosystem Working Group**

[![IDB Logo](https://scldata.iadb.org/assets/iadb-7779368a000004449beca0d4fc6f116cc0617572d549edf2ae491e9a17f63778.png)](https://scldata.iadb.org)


<h1 align="center"> analytics_simulation_public_policy_scl </h1>

Este código realiza **


## Tareas: 

1. Concat Armonizada
- Roberto - Crear un concat latest con el último año de cada país (revisar consistencia)
- Roberto - Comparar población obtenida e identificar países con posibles problemas de armonización.
    - Lina - volver a correr armonización ajustando el factor de expansión (arg 2020)

2. Líneas:
- Laura y Lina - generar catálogo con variables de segmento y líneas oficiales
    - Guardar nombre de la variable de segmentación (1 o más)

```

            isoalpha3| year | key    | value  | lp_ci | lpe_ci
            COL      | 2010 | zona_c | 0      |   *   | ****
            BOL      | 2010 | ciudad | 1      |   *   | ****
```


3. Ingreso:
- Lina: Identificar países que tengan ingreso oficiales ya en la encuesta
- Lina y Lau: Para los que no reconstruir una variable adicional de - ingreso oficial (no sobreescribir ingreso BID)

4. Pobreza:
- Identificar paises para los que ya venga la variable de pobreza
- Generar pobreza con líneas oficiales (2) e ingreso oficial (3)

5. Comparación
- Crear un excel de referencia por país año los datos oficiales de pobreza para comparar. 
        
6. Simulación
    - Roberto - script para asociar concat anual con líneas oficiales 
    - Roberto - calcular pobreza
            
## Tabla de contenidos: 
--- 
- [Descripción y contexto](#descripción-y-contexto)
- [Guía de usuario](#guía-de-usuario)
- [Autor/es](#autores)


## Descripción y contexto
---

## Guía de usuario
---


## Autor/es
--- 
