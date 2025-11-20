# Proyecto Servicios Nube

# **Proyecto Final (30%) – Servicios en la Nube 2025-02**

Número de integrantes: **3**

Fecha de sustentación: **Semana del 27 de octubre (provisional)**

Tiempo máximo de sustentación: **20 minutos**

Repositorio: [https://github.com/adatapoint/servicios-nube-proyecto-2025](https://github.com/adatapoint/servicios-nube-proyecto-2025)

La empresa **NexaCloud** desea migrar su infraestructura on-premise a la nube. Como arquitectos cloud, deben aprovisionar todos los componentes necesarios para un servicio interno tipo intranet.

La aplicación tendrá **5 páginas** que deben conectarse con la infraestructura AWS que ustedes desplegarán.

---

## **1. Web Page (EC2, SSH)**

Página HTML simple que muestra el nombre de la empresa.

Sirve como verificación del despliegue exitoso.

---

## **2. Bases de Datos (RDS, Security Groups, VPC)**

Muestra datos de una base de datos cuyo DDL es provisto.

Acceso externo permitido solo por el puerto **9876**.

---

## **3. Imágenes en bucket (S3, Lambda, API Gateway, VPC)**

Muestra imágenes de empleados.

La API Gateway actúa como Event Source de Lambda, que extrae imágenes desde S3.

La Lambda debe ser programada por el equipo.

---

## **4. Lambda function (Lambda, API Gateway)**

Botón en la web que llama a API Gateway.

Este dispara una Lambda que **inserta los datos de ambos integrantes** en la tabla `estudiantes`.

---

## **5. Monitoreo y Alertas (CloudWatch, SNS)**

Configurar alertas y métricas para los servicios implementados.

---

## **6. Balanceador de carga (ELB, EC2)**

Página embebida servida por un **Load Balancer**.

Debe mostrar un identificador único del servidor EC2 que la atiende.

El balanceador tendrá múltiples instancias EC2 detrás, escalables manualmente.

---

# **Buenas Prácticas Requeridas por NexaCloud**

- Ningún acceso no autorizado a recursos de nube.
- **API Gateway protegido** mediante API Key.
- Buckets **no públicos**.
- Configuraciones seguras y mínimo acceso posible.
- Gestión eficiente de costos: la empresa no tolera gastos innecesarios.
- Selección de instancias económicas.

---

# **Documentos Adicionales del Proyecto**

## **Estimación de costos**

Reporte detallado de costos estimados para 6 meses.

## **Informe técnico**

Descripción completa de la arquitectura desplegada, con diagramas de red/topología.

## **Requisitos adicionales**

- La app web principal *no la desarrolla el equipo*.
- Sí deben desarrollar todas las **funciones Lambda**.
- SSH debe estar bloqueado o en puerto distinto al 22.
- Pueden usar cualquier cliente para conectarse a la base de datos (se recomienda DBeaver).
- Las imágenes del bucket serán entregadas por NexaCloud.

---

Si deseas, puedo **convertir cada archivo a un .md descargable**, o **unir ambos en un único documento más elegante y con estilo profesional**.

# **Rúbrica de Evaluación – Proyecto Final**

*Servicios en la Nube 2025-2*

## **1. Web Page — 0.1**

Página web sencilla (solo HTML) que muestra el nombre de la empresa.

Permite verificar que el despliegue es exitoso.

---

## **2. Bases de Datos — 0.55**

Muestra datos de una base de datos.

Se proveen el DDL y los datos.

La conexión externa debe realizarse por el puerto **9876**.

---

## **3. Imágenes en bucket — 0.75**

Muestra imágenes de empleados extraídas por una **API Gateway**.

Sirve como *Event Source* para una función Lambda que extrae imágenes desde un bucket S3.

El bucket debe crearse y poblarse.

---

## **4. Lambda function — 0.75**

Botón que llama a un API Gateway.

El API Gateway dispara una Lambda que **inserta en la base de datos** los datos de ambos integrantes del equipo en la tabla `estudiantes`.

---

## **5. Monitoreo y Alertas — 0.75**

Monitorizar servicios y crear alertas sobre umbrales o eventos relevantes.

---

## **6. Buenas prácticas — 0.3**

Todos los servicios deben implementarse siguiendo normas de seguridad, privacidad y buenas prácticas de la industria.

---

## **7. Estimación de costos — 0.4**

Reporte estimado de costos para los próximos seis meses.

---

## **8. Informe técnico — 0.4**

Documentación técnica de los servicios desplegados, topologías de red y configuración de seguridad.

---

## **9. Balanceador de carga — 1.0**

Página web embebida recargada constantemente.

Debe ser servida por un **Load Balancer**, mostrando el identificador único del servidor.

Detrás del balanceador debe haber múltiples servidores EC2 con capacidad de escalado manual.

---