-- ============================================================
-- N° 01 | CATEGORÍA: INSERT
-- OPERACIÓN: Insertar propietario
-- DESCRIPCIÓN: Agrega un nuevo propietario a la tabla owners.
-- TABLA DESTINO: tourism.owners
-- NOTA: owner_id se genera automáticamente con SEQUENCE.
-- ============================================================

INSERT INTO tourism.owners (
    first_name, last_name, company_name, email, phone,
    tax_id, address_line1, city, state, country, postal_code
)
VALUES (
    'Carlos', 'Mendoza', 'Hospedajes Mendoza S.A.',
    'carlos.mendoza@example.com', '+503 7777-8888',
    'SV-123456789', 'Calle Los Almendros 45',
    'San Salvador', 'San Salvador', 'El Salvador', '01101'
);


-- ============================================================
-- N° 02 | CATEGORÍA: INSERT
-- OPERACIÓN: Insertar alojamiento
-- DESCRIPCIÓN: Crea primero la ubicación y luego el alojamiento
--              vinculándolo al propietario y ubicación creados.
-- TABLAS: tourism.locations → tourism.accommodations
-- NOTA: Se usa SELECT MAX(location_id) para recuperar el ID
--       recién insertado sin necesidad de RETURNING.
-- ============================================================

-- PASO 1: Insertar la ubicación del alojamiento
INSERT INTO tourism.locations (
    country, state, city, address_line1, postal_code,
    latitude, longitude
)
VALUES (
    'El Salvador', 'La Libertad', 'La Libertad',
    'Playa El Tunco, Km 42 Carretera Litoral',
    '01601', 13.4932, -89.3918
);
-- PASO 2: Insertar el alojamiento usando el location_id recién creado
INSERT INTO tourism.accommodations (
    owner_id, accommodation_type_id, location_id,
    name, description, max_guests,
    bedroom_count, bathroom_count, base_price_per_night,
    currency_code, check_in_time, check_out_time
)
VALUES (
    21, 3,
    (SELECT MAX(location_id) FROM tourism.locations),
    'Villa El Tunco', 'Hermosa villa frente al mar con vista al océano Pacífico.',
    8, 4, 3, 185.00, 'USD', '15:00:00', '11:00:00'
);


-- ============================================================
-- N° 03 | CATEGORÍA: INSERT
-- OPERACIÓN: Huésped y reserva
-- DESCRIPCIÓN: Registra un huésped nuevo y crea su primera reserva.
--              El booking usa una subconsulta para obtener el guest_id
--              sin necesidad de conocerlo previamente.
-- TABLAS: tourism.guests → tourism.bookings
-- CONSTRAINT: booking_reference debe ser único (UNIQUE).
-- ============================================================

-- PASO 1: Registrar el huésped
INSERT INTO tourism.guests (
    first_name, last_name, email, phone,
    date_of_birth, nationality
)
VALUES (
    'María', 'González', 'maria.gonzalez@example.com',
    '+503 6666-1234', '1990-05-15', 'El Salvador'
);
-- PASO 2: Crear la reserva vinculada al huésped recién insertado
INSERT INTO tourism.bookings (
    guest_id, accommodation_id, booking_status_id,
    check_in_date, check_out_date,
    adult_count, child_count,
    subtotal_amount, tax_amount, discount_amount, total_amount,
    booking_reference
)
VALUES (
    (SELECT guest_id FROM tourism.guests
     WHERE email = 'maria.gonzalez@example.com'),
    1, 1,
    '2026-07-10', '2026-07-15',
    2, 0,
    1770.00, 212.40, 0.00, 1982.40,
    'BK-TEST0001'
);

-- ============================================================
-- N° 04 | CATEGORÍA: INSERT
-- OPERACIÓN: Insertar pago
-- DESCRIPCIÓN: Registra el pago completo de la reserva BK-TEST0001.
--              Se usa subconsulta para obtener el booking_id a partir
--              del booking_reference, y to_char() para generar un
--              transaction_reference único basado en timestamp.
-- TABLA DESTINO: tourism.payments
-- FK: booking_id → tourism.bookings (ON DELETE CASCADE)
-
INSERT INTO tourism.payments (
    booking_id, amount, payment_method,
    payment_status, transaction_reference
)
VALUES (
    (SELECT booking_id FROM tourism.bookings
     WHERE booking_reference = 'BK-TEST0001'),
    1982.40,
    'CreditCard',
    'Completed',
    'TXN-' || to_char(now(), 'YYYYMMDDHH24MISS')
);

-- ============================================================
-- N° 05 | CATEGORÍA: SELECT
-- OPERACIÓN: Alojamientos activos
-- DESCRIPCIÓN: Filtra únicamente los alojamientos con is_active = TRUE.
--              Incluye el nombre del tipo mediante un INNER JOIN.
-- TABLAS: accommodations ⟶ accommodation_types
-- ORDEN: De mayor a menor precio por noche.
-
SELECT
    a.accommodation_id,
    a.name,
    at.type_name,
    a.base_price_per_night,
    a.currency_code,
    a.max_guests
FROM tourism.accommodations a
INNER JOIN tourism.accommodation_types at
    ON a.accommodation_type_id = at.accommodation_type_id
WHERE a.is_active = TRUE
ORDER BY a.base_price_per_night DESC;

-- ============================================================
-- N° 06 | CATEGORÍA: SELECT
-- OPERACIÓN: Huéspedes por país
-- DESCRIPCIÓN: Filtra huéspedes según su campo nationality.
--              Útil para reportes de mercado por origen geográfico.
-- TABLA: tourism.guests
-- NOTA: El campo nationality es texto libre; cambiar el valor
--       del WHERE para filtrar otro país.
-- ============================================================
SELECT
    g.guest_id,
    g.first_name,
    g.last_name,
    g.email,
    g.nationality
FROM tourism.guests g
WHERE g.nationality = 'El Salvador'
ORDER BY g.last_name, g.first_name;

-- ============================================================
-- N° 07 | CATEGORÍA: SELECT
-- OPERACIÓN: Reservas por fechas
-- DESCRIPCIÓN: Usa el operador BETWEEN para recuperar reservas
--              cuyo check_in_date cae dentro del año 2026.
--              BETWEEN es equivalente a >= fecha_inicio AND <= fecha_fin.
-- TABLAS: bookings ⟶ guests
-- ============================================================
SELECT
    b.booking_id,
    b.booking_reference,
    g.first_name || ' ' || g.last_name  AS huesped,
    b.check_in_date,
    b.check_out_date,
    b.total_nights,
    b.total_amount
FROM tourism.bookings b
INNER JOIN tourism.guests g ON b.guest_id = g.guest_id
WHERE b.check_in_date BETWEEN '2026-01-01' AND '2026-12-31'
ORDER BY b.check_in_date;

-- ============================================================
-- N° 08 | CATEGORÍA: UPDATE
-- OPERACIÓN: Actualizar precio
-- DESCRIPCIÓN: Aplica un aumento del 10% al precio base por noche
--              del alojamiento con accommodation_id = 1.
--              Se actualiza también updated_at para mantener auditoría.
-- TABLA: tourism.accommodations
-- PRECAUCIÓN: Verificar el ID antes de ejecutar.
-- ============================================================

UPDATE tourism.accommodations
SET
    base_price_per_night = base_price_per_night * 1.10,
    updated_at = CURRENT_TIMESTAMP
WHERE accommodation_id = 1;
-- ============================================================
-- N° 09 | CATEGORÍA: UPDATE
-- OPERACIÓN: Estado reserva
-- DESCRIPCIÓN: Cambia el estado de la reserva BK-TEST0001 a 'Confirmed'.
--              Se usa una subconsulta para obtener el booking_status_id
--              por nombre en lugar de hardcodear el ID numérico.
-- TABLAS: bookings ← booking_statuses (subconsulta)
-- ESTADOS VÁLIDOS: Pending | Confirmed | CheckedIn | CheckedOut |
--                  Cancelled | NoShow
-- ============================================================

UPDATE tourism.bookings
SET
    booking_status_id = (
        SELECT booking_status_id
        FROM tourism.booking_statuses
        WHERE status_name = 'Confirmed'
    ),
    updated_at = CURRENT_TIMESTAMP
WHERE booking_reference = 'BK-TEST0001';


-- ============================================================
-- N° 10 | CATEGORÍA: DELETE
-- OPERACIÓN: Eliminar reseña
-- DESCRIPCIÓN: Elimina la reseña con review_id = 1, pero solo si
--              pertenece al huésped identificado por su email.
--              La doble condición evita borrar reseñas ajenas.
-- TABLA: tourism.reviews
-- PRECAUCIÓN: Esta operación es irreversible. Verificar antes
--             con SELECT usando las mismas condiciones WHERE.
-- ============================================================

-- Verificación previa recomendada:
-- SELECT * FROM tourism.reviews WHERE review_id = 1;
DELETE FROM tourism.reviews
WHERE review_id = 1
  AND guest_id = (
      SELECT guest_id FROM tourism.guests
      WHERE email = 'mauraferrer@example.com'
  );

-- ============================================================
-- N° 11 | CATEGORÍA: JOIN
-- OPERACIÓN: Reservas + huésped
-- DESCRIPCIÓN: Combina bookings con guests y booking_statuses
--              mediante INNER JOIN para mostrar reservas con nombre
--              del huésped y nombre legible del estado.
--              Solo devuelve filas con coincidencia en todas las tablas.
-- TABLAS: bookings ⟶ guests | bookings ⟶ booking_statuses
-- ============================================================
SELECT
    b.booking_reference,
    g.first_name || ' ' || g.last_name   AS huesped,
    g.email,
    g.nationality,
    bs.status_name                        AS estado,
    b.check_in_date,
    b.check_out_date,
    b.total_amount
FROM tourism.bookings b
INNER JOIN tourism.guests g
    ON b.guest_id = g.guest_id
INNER JOIN tourism.booking_statuses bs
    ON b.booking_status_id = bs.booking_status_id
ORDER BY b.check_in_date DESC;

-- ============================================================
-- N° 12 | CATEGORÍA: JOIN
-- OPERACIÓN: Alojamiento completo
-- DESCRIPCIÓN: Une cuatro tablas para obtener una vista enriquecida:
--              tipo de alojamiento, nombre del propietario y ciudad.
--              Usa múltiples INNER JOIN encadenados.
--              Solo devuelve alojamientos activos.
-- TABLAS: accommodations ⟶ accommodation_types
--                        ⟶ owners
--                        ⟶ locations
-- ============================================================
SELECT
    a.name                           AS alojamiento,
    at.type_name                     AS tipo,
    o.first_name || ' ' || o.last_name AS propietario,
    l.city                           AS ciudad,
    l.country                        AS pais,
    a.base_price_per_night,
    a.currency_code,
    a.max_guests
FROM tourism.accommodations a
INNER JOIN tourism.accommodation_types at
    ON a.accommodation_type_id = at.accommodation_type_id
INNER JOIN tourism.owners o
    ON a.owner_id = o.owner_id
INNER JOIN tourism.locations l
    ON a.location_id = l.location_id
WHERE a.is_active = TRUE
ORDER BY a.name;


-- ============================================================
-- N° 13 | CATEGORÍA: JOIN
-- OPERACIÓN: Pagos + reservas
-- DESCRIPCIÓN: Combina pagos con reservas y huéspedes para mostrar
--              quién pagó, cuánto y por qué reserva.
--              La cadena es: payments → bookings → guests.
-- TABLAS: payments ⟶ bookings ⟶ guests
-- ============================================================

SELECT
    p.payment_id,
    b.booking_reference,
    g.first_name || ' ' || g.last_name AS huesped,
    p.payment_date,
    p.amount,
    p.payment_method,
    p.payment_status
FROM tourism.payments p
INNER JOIN tourism.bookings b
    ON p.booking_id = b.booking_id
INNER JOIN tourism.guests g
    ON b.guest_id = g.guest_id
ORDER BY p.payment_date DESC;

-- ============================================================
-- N° 14 | CATEGORÍA: LEFT JOIN
-- OPERACIÓN: Sin reseñas
-- DESCRIPCIÓN: LEFT JOIN entre bookings y reviews incluye TODAS las
--              reservas, poniendo NULL en las columnas de reviews
--              cuando no existe reseña. El WHERE IS NULL filtra solo
--              las que no tienen reseña → patrón "anti-join".
-- TABLAS: bookings ⟶ guests | bookings ⟶ accommodations
--         bookings ←(LEFT) reviews
-- USO: Identificar reservas pendientes de solicitar reseña.
-- ============================================================

SELECT
    b.booking_reference,
    g.first_name || ' ' || g.last_name AS huesped,
    a.name                              AS alojamiento,
    b.check_out_date,
    r.review_id
FROM tourism.bookings b
INNER JOIN tourism.guests g
    ON b.guest_id = g.guest_id
INNER JOIN tourism.accommodations a
    ON b.accommodation_id = a.accommodation_id
LEFT JOIN tourism.reviews r
    ON b.booking_id = r.booking_id
WHERE r.review_id IS NULL
ORDER BY b.check_out_date DESC;

-- ============================================================
-- N° 15 | CATEGORÍA: LEFT JOIN
-- OPERACIÓN: Sin reservas
-- DESCRIPCIÓN: LEFT JOIN desde guests hacia bookings devuelve todos
--              los huéspedes. Donde no hay reserva, booking_id = NULL.
--              El WHERE IS NULL aísla los huéspedes sin ninguna reserva.
-- TABLAS: guests ←(LEFT) bookings
-- USO: Detectar cuentas inactivas o potenciales clientes a reactivar.
-- ============================================================
SELECT
    g.guest_id,
    g.first_name || ' ' || g.last_name AS huesped,
    g.email,
    g.nationality
FROM tourism.guests g
LEFT JOIN tourism.bookings b
    ON g.guest_id = b.guest_id
WHERE b.booking_id IS NULL
ORDER BY g.last_name;
-- N° 16 | CATEGORÍA: AGG (Agregación)
-- OPERACIÓN: Total ingresos
-- DESCRIPCIÓN: Agrupa pagos por alojamiento y calcula:
--              - ingresos_brutos: SUM de todos los pagos
--              - ingresos_confirmados: SUM solo de pagos 'Completed'
--              Se usa CASE dentro de SUM para el filtro condicional.
-- TABLAS: payments ⟶ bookings ⟶ accommodations
-- ============================================================


SELECT
    a.name                           AS alojamiento,
    COUNT(p.payment_id)              AS total_pagos,
    SUM(p.amount)                    AS ingresos_brutos,
    SUM(CASE WHEN p.payment_status = 'Completed'
             THEN p.amount ELSE 0 END) AS ingresos_confirmados
FROM tourism.payments p
INNER JOIN tourism.bookings b
    ON p.booking_id = b.booking_id
INNER JOIN tourism.accommodations a
    ON b.accommodation_id = a.accommodation_id
GROUP BY a.accommodation_id, a.name
ORDER BY ingresos_confirmados DESC;
-- ============================================================
-- N° 17 | CATEGORÍA: AGG (Agregación)
-- OPERACIÓN: Promedio rating
-- DESCRIPCIÓN: Calcula estadísticas de rating (1-5) por alojamiento:
--              promedio redondeado a 2 decimales, mínimo y máximo.
--              Solo incluye alojamientos que tienen al menos 1 reseña
--              (INNER JOIN excluye los que no tienen).
-- TABLAS: accommodations ⟶ reviews
-- ============================================================
SELECT
    a.name                  AS alojamiento,
    COUNT(r.review_id)      AS total_resenas,
    ROUND(AVG(r.rating), 2) AS rating_promedio,
    MIN(r.rating)           AS rating_min,
    MAX(r.rating)           AS rating_max
FROM tourism.accommodations a
INNER JOIN tourism.reviews r
    ON a.accommodation_id = r.accommodation_id
GROUP BY a.accommodation_id, a.name
ORDER BY rating_promedio DESC;
-- ============================================================
-- N° 18 | CATEGORÍA: AGG (Agregación)
-- OPERACIÓN: Top alojamientos
-- DESCRIPCIÓN: Cuenta reservas por alojamiento y devuelve los 5
--              con más reservas. Usa LEFT JOIN para incluir también
--              alojamientos sin reservas (con COUNT = 0).
--              LIMIT 5 restringe el resultado al top 5.
-- TABLAS: accommodations ⟶ accommodation_types
--         accommodations ←(LEFT) bookings
-- ============================================================
SELECT
    a.name                  AS alojamiento,
    at.type_name            AS tipo,
    COUNT(b.booking_id)     AS total_reservas,
    SUM(b.total_amount)     AS ingresos_totales
FROM tourism.accommodations a
INNER JOIN tourism.accommodation_types at
    ON a.accommodation_type_id = at.accommodation_type_id
LEFT JOIN tourism.bookings b
    ON a.accommodation_id = b.accommodation_id
GROUP BY a.accommodation_id, a.name, at.type_name
ORDER BY total_reservas DESC
LIMIT 5;
-- ============================================================
-- N° 19 | CATEGORÍA: HAVING
-- OPERACIÓN: Más de 3 reservas
-- DESCRIPCIÓN: HAVING filtra DESPUÉS de agrupar (a diferencia de WHERE
--              que filtra antes). Permite condicionar sobre el resultado
--              de funciones de agregación como COUNT().
--              Devuelve solo huéspedes con más de 3 reservas.
-- TABLAS: guests ⟶ bookings
-- DIFERENCIA WHERE vs HAVING:
--   WHERE  → filtra filas individuales (antes del GROUP BY)
--   HAVING → filtra grupos agregados  (después del GROUP BY)
-- ============================================================
SELECT
    g.guest_id,
    g.first_name || ' ' || g.last_name AS huesped,
    g.email,
    g.nationality,
    COUNT(b.booking_id)                AS total_reservas,
    SUM(b.total_amount)                AS gasto_total
FROM tourism.guests g
INNER JOIN tourism.bookings b
    ON g.guest_id = b.guest_id
GROUP BY g.guest_id, g.first_name, g.last_name,
         g.email, g.nationality
HAVING COUNT(b.booking_id) > 3
ORDER BY total_reservas DESC;

-- ============================================================
-- N° 20 | CATEGORÍA: Subconsulta
-- OPERACIÓN: Alojamiento más caro
-- DESCRIPCIÓN: La subconsulta interna calcula el precio máximo entre
--              todos los alojamientos activos. La consulta externa
--              recupera los alojamientos que igualan ese máximo.
--              Ventaja frente a ORDER BY + LIMIT 1: maneja empates
--              correctamente, devolviendo todos los que comparten
--              el precio más alto.
-- TABLAS: accommodations ⟶ accommodation_types ⟶ locations
-- SUBCONSULTA: SELECT MAX(base_price_per_night) → valor escalar
-- ============================================================
SELECT
    a.accommodation_id,
    a.name,
    at.type_name,
    a.base_price_per_night,
    a.currency_code,
    l.city,
    l.country
FROM tourism.accommodations a
INNER JOIN tourism.accommodation_types at
    ON a.accommodation_type_id = at.accommodation_type_id
INNER JOIN tourism.locations l
    ON a.location_id = l.location_id
WHERE a.base_price_per_night = (
    SELECT MAX(base_price_per_night)
    FROM tourism.accommodations
    WHERE is_active = TRUE
)
  AND a.is_active = TRUE;
