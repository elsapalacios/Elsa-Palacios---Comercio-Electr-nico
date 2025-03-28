-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 28-03-2025 a las 06:32:52
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `database_comercio_electronico`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `ActualizarStock` (IN `p_Id_producto` INT, IN `p_cantidad` INT)   BEGIN
    UPDATE productos SET stock = p_cantidad WHERE Id_producto = p_Id_producto;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AplicarCupon` (IN `p_Id_orden` INT, IN `p_codigo` VARCHAR(100))   BEGIN
    DECLARE v_descuento DECIMAL(10,2);
    
    SELECT descuento INTO v_descuento FROM cupones WHERE codigo = p_codigo 
    AND fecha_inicio <= NOW() AND fecha_fin >= NOW();
    
    IF v_descuento IS NOT NULL THEN
        UPDATE ordenes SET estado = 'Descuento aplicado' WHERE Id_orden = p_Id_orden;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cupón no válido';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CrearOrden` (IN `usuario_id` INT, IN `productos` JSON)   BEGIN
    DECLARE orden_id INT;
    DECLARE total DECIMAL(10,2) DEFAULT 0;
    DECLARE producto_id INT;
    DECLARE cantidad INT;
    DECLARE precio_unitario DECIMAL(10,2);
    DECLARE i INT DEFAULT 0;
    DECLARE productos_count INT;

    -- Crear la orden
    INSERT INTO ordenes (Id_usuario, fecha_orden, estado)
    VALUES (usuario_id, CURDATE(), 'Preparando');
    
    SET orden_id = LAST_INSERT_ID();
    
    -- Obtener la cantidad de productos en la lista
    SET productos_count = JSON_LENGTH(productos);
    
    WHILE i < productos_count DO
        -- Extraer datos del producto actual
        SET producto_id = JSON_UNQUOTE(JSON_EXTRACT(productos, CONCAT('$[', i, '].Id_producto')));
        SET cantidad = JSON_UNQUOTE(JSON_EXTRACT(productos, CONCAT('$[', i, '].cantidad')));
        
        -- Obtener el precio unitario del producto
        SELECT precio INTO precio_unitario FROM productos WHERE Id_producto = producto_id;
        
        -- Insertar el detalle de la orden
        INSERT INTO detalles_Orden (Id_orden, Id_producto, cantidad, precio_unitario)
        VALUES (orden_id, producto_id, cantidad, precio_unitario);
        
        -- Calcular el total de la orden
        SET total = total + (cantidad * precio_unitario);
        
        -- Actualizar el stock del producto
        UPDATE productos 
        SET stock = stock - cantidad 
        WHERE Id_producto = producto_id;
        
        SET i = i + 1;
    END WHILE;

    -- Registrar el pago (puedes modificar esto según el método de pago que manejes)
    INSERT INTO pagos (Id_orden, monto, metodo_pago, fecha_pago)
    VALUES (orden_id, total, 'Efectivo', CURDATE());

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GenerarReporteVentas` (IN `fecha_inicio` DATE, IN `fecha_fin` DATE)   BEGIN
    SELECT 
        p.Id_producto,
        p.nombre AS producto,
        SUM(v.cantidad) AS total_cantidad_vendida,
        SUM(v.precio_venta * v.cantidad) AS total_ventas
    FROM ventas v
    JOIN productos p ON v.Id_producto = p.Id_producto
    WHERE v.fecha_venta BETWEEN fecha_inicio AND fecha_fin
    GROUP BY p.Id_producto, p.nombre
    ORDER BY total_ventas DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ObtenerProductosCategoria` (IN `p_Id_categoria` INT)   BEGIN
    SELECT * FROM productos WHERE Id_categoria = p_Id_categoria;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `Aplicar_Impuesto` (`p_monto` DECIMAL(10,2), `p_Id_impuesto` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE tasa DECIMAL(10,2);
    DECLARE monto_final DECIMAL(10,2);

    -- Obtener la tasa del impuesto correspondiente
    SELECT tasa INTO tasa
    FROM impuestos
    WHERE Id_impuesto = p_Id_impuesto;

    -- Si no se encuentra el impuesto, devolver el monto original
    IF tasa IS NULL THEN
        RETURN p_monto;
    END IF;

    -- Calcular el monto con el impuesto aplicado
    SET monto_final = p_monto + (p_monto * tasa / 100);

    RETURN monto_final;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `CalcularTotalOrden` (`p_Id_orden` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE total DECIMAL(10,2);

    -- Calcula el total sumando cantidad * precio_unitario de cada producto en la orden
    SELECT SUM(cantidad * precio_unitario) 
    INTO total
    FROM detalles_orden
    WHERE Id_orden = p_Id_orden;

    -- Devuelve el total calculado
    RETURN IFNULL(total, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Obtener_Nombre_Usuario` (`p_Id_usuario` INT) RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_spanish_ci DETERMINISTIC BEGIN
    DECLARE nombre VARCHAR(100);

    -- Obtiene el nombre del usuario con el ID proporcionado
    SELECT nombre_usuario 
    INTO nombre
    FROM usuarios
    WHERE Id_usuario = p_Id_usuario;

    -- Devuelve el nombre encontrado (o NULL si no existe)
    RETURN nombre;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `Id_categoria` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`Id_categoria`, `nombre`) VALUES
(1, 'Deportes'),
(2, 'Computación'),
(3, 'Juguetes'),
(4, 'Automóviles'),
(5, 'Salud y Belleza');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `Id_cliente` int(11) NOT NULL,
  `nombre_cliente` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `telefono` varchar(100) DEFAULT NULL,
  `direccion` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras_proveedores`
--

CREATE TABLE `compras_proveedores` (
  `Id_compra` int(11) NOT NULL,
  `Id_proveedor` int(11) DEFAULT NULL,
  `Id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio_compra` decimal(10,2) DEFAULT NULL,
  `fecha_compra` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuracion_sitio`
--

CREATE TABLE `configuracion_sitio` (
  `Id_configuracion` int(11) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `valor` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `configuracion_sitio`
--

INSERT INTO `configuracion_sitio` (`Id_configuracion`, `nombre`, `valor`) VALUES
(1, 'Tiempo de espera de compra', '10 minutos'),
(2, 'Modo Mantenimiento', 'Desactivado'),
(3, 'Zona Horaria', 'GMT-5'),
(4, 'Impuesto Predeterminado', '19%'),
(5, 'Moneda Alternativa', 'USD');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cupones`
--

CREATE TABLE `cupones` (
  `Id_cupon` int(11) NOT NULL,
  `codigo` varchar(100) DEFAULT NULL,
  `descuento` decimal(10,2) DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `cupones`
--

INSERT INTO `cupones` (`Id_cupon`, `codigo`, `descuento`, `fecha_inicio`, `fecha_fin`) VALUES
(1, 'DESCUENTO5', 5.00, '2025-04-01', '2025-05-01'),
(2, 'NAVIDAD20', 20.00, '2025-12-01', '2025-12-31'),
(3, 'VERANO15', 15.00, '2025-06-01', '2025-06-30'),
(4, 'FREESHIP', 10.00, '2025-07-01', '2025-07-31'),
(5, 'PRIMERA10', 10.00, '2025-08-01', '2025-08-31');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `departamentos_empleados`
--

CREATE TABLE `departamentos_empleados` (
  `Id_departamento` int(11) NOT NULL,
  `nombre_departamento` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_orden`
--

CREATE TABLE `detalles_orden` (
  `Id_detalle` int(11) NOT NULL,
  `Id_orden` int(11) DEFAULT NULL,
  `Id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio_unitario` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `detalles_orden`
--

INSERT INTO `detalles_orden` (`Id_detalle`, `Id_orden`, `Id_producto`, `cantidad`, `precio_unitario`) VALUES
(1, 3, 2, 1, 35.00),
(2, 4, 3, 2, 75.00),
(3, 5, 4, 3, 25.00),
(4, 1, 5, 2, 15.00),
(5, 2, 1, 1, 1200.00);

--
-- Disparadores `detalles_orden`
--
DELIMITER $$
CREATE TRIGGER `Antes_de_Insertar_en_Detalles_Orden` BEFORE INSERT ON `detalles_orden` FOR EACH ROW BEGIN
    DECLARE stock_disponible INT;
    
    -- Obtener el stock disponible del producto
    SELECT stock INTO stock_disponible
    FROM productos
    WHERE Id_producto = NEW.Id_producto;
    
    -- Verificar si hay suficiente stock
    IF stock_disponible < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Stock insuficiente para este producto';
    ELSE
        -- Reducir el stock del producto
        UPDATE productos 
        SET stock = stock - NEW.cantidad 
        WHERE Id_producto = NEW.Id_producto;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `direcciones_usuarios`
--

CREATE TABLE `direcciones_usuarios` (
  `Id_direccion` int(11) NOT NULL,
  `Id_usuario` int(11) DEFAULT NULL,
  `direccion` varchar(100) DEFAULT NULL,
  `ciudad` varchar(100) DEFAULT NULL,
  `codigo_postal` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `direcciones_usuarios`
--

INSERT INTO `direcciones_usuarios` (`Id_direccion`, `Id_usuario`, `direccion`, `ciudad`, `codigo_postal`) VALUES
(1, 3, 'Calle 777', 'Ciudad J', '10010'),
(2, 4, 'Avenida 888', 'Ciudad K', '11011'),
(3, 5, 'Calle 999', 'Ciudad L', '12012'),
(4, 1, 'Avenida 1010', 'Ciudad M', '13013'),
(5, 2, 'Calle 1111', 'Ciudad N', '14014');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empleados`
--

CREATE TABLE `empleados` (
  `Id_empleado` int(11) NOT NULL,
  `Id_departamento` int(11) DEFAULT NULL,
  `nombre_empleado` varchar(100) DEFAULT NULL,
  `cargo` varchar(100) DEFAULT NULL,
  `salario` decimal(10,2) DEFAULT NULL,
  `fecha_contratacion` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `envios`
--

CREATE TABLE `envios` (
  `Id_envio` int(11) NOT NULL,
  `Id_orden` int(11) DEFAULT NULL,
  `direccion` varchar(100) DEFAULT NULL,
  `ciudad` varchar(100) DEFAULT NULL,
  `codigo_postal` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `envios`
--

INSERT INTO `envios` (`Id_envio`, `Id_orden`, `direccion`, `ciudad`, `codigo_postal`) VALUES
(1, 3, 'Calle 222', 'Ciudad E', '50005'),
(2, 4, 'Avenida 333', 'Ciudad F', '60006'),
(3, 5, 'Calle 444', 'Ciudad G', '70007'),
(4, 1, 'Avenida 555', 'Ciudad H', '80008'),
(5, 2, 'Calle 666', 'Ciudad I', '90009');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historial_precios`
--

CREATE TABLE `historial_precios` (
  `Id_historial` int(11) NOT NULL,
  `Id_producto` int(11) DEFAULT NULL,
  `precio_anterior` decimal(10,2) DEFAULT NULL,
  `precio_nuevo` decimal(10,2) DEFAULT NULL,
  `fecha_cambio` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `historial_precios`
--

INSERT INTO `historial_precios` (`Id_historial`, `Id_producto`, `precio_anterior`, `precio_nuevo`, `fecha_cambio`) VALUES
(1, 2, 30.00, 35.00, '2025-03-28'),
(2, 3, 70.00, 75.00, '2025-03-29'),
(3, 4, 22.00, 25.00, '2025-03-30'),
(4, 5, 12.00, 15.00, '2025-03-31'),
(5, 1, 1150.00, 1200.00, '2025-04-01');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `imagenes_productos`
--

CREATE TABLE `imagenes_productos` (
  `Id_imagen` int(11) NOT NULL,
  `Id_producto` int(11) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `imagenes_productos`
--

INSERT INTO `imagenes_productos` (`Id_imagen`, `Id_producto`, `url`) VALUES
(1, 2, 'lampara_led.jpg'),
(2, 3, 'zapatillas.jpg'),
(3, 4, 'juguete.jpg'),
(4, 5, 'shampoo.jpg'),
(5, 1, 'laptop.jpg');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `impuestos`
--

CREATE TABLE `impuestos` (
  `Id_impuesto` int(11) NOT NULL,
  `nombre_impuesto` varchar(100) DEFAULT NULL,
  `tasa` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `impuestos`
--

INSERT INTO `impuestos` (`Id_impuesto`, `nombre_impuesto`, `tasa`) VALUES
(1, 'IVA Reducido', 10.00),
(2, 'Impuesto Ambiental', 8.00),
(3, 'Impuesto al Consumo', 12.00),
(4, 'Impuesto Especial', 5.00),
(5, 'Tasa de Servicio', 15.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inventario`
--

CREATE TABLE `inventario` (
  `Id_inventario` int(11) NOT NULL,
  `Id_producto` int(11) DEFAULT NULL,
  `Id_proveedor` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `ubicacion` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `inventario`
--

INSERT INTO `inventario` (`Id_inventario`, `Id_producto`, `Id_proveedor`, `cantidad`, `ubicacion`) VALUES
(1, 2, 3, 200, 'Bodega 3'),
(2, 3, 4, 150, 'Bodega 4'),
(3, 4, 5, 300, 'Bodega 5'),
(4, 5, 1, 250, 'Bodega 1'),
(5, 1, 2, 180, 'Bodega 2');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs_sistema`
--

CREATE TABLE `logs_sistema` (
  `Id_log` int(11) NOT NULL,
  `Id_usuario` int(11) DEFAULT NULL,
  `accion` varchar(100) DEFAULT NULL,
  `tabla_afectada` varchar(100) DEFAULT NULL,
  `fecha_hora` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `logs_sistema`
--

INSERT INTO `logs_sistema` (`Id_log`, `Id_usuario`, `accion`, `tabla_afectada`, `fecha_hora`) VALUES
(1, 2, 'Eliminar', 'productos', '2025-03-28 10:00:00'),
(2, 3, 'Modificar', 'clientes', '2025-03-29 11:30:00'),
(3, 4, 'Insertar', 'envios', '2025-03-30 12:45:00'),
(4, 5, 'Actualizar', 'cupones', '2025-03-31 14:00:00'),
(5, 1, 'Consultar', 'ventas', '2025-04-01 15:15:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ordenes`
--

CREATE TABLE `ordenes` (
  `Id_orden` int(11) NOT NULL,
  `Id_usuario` int(11) DEFAULT NULL,
  `fecha_orden` date DEFAULT NULL,
  `estado` enum('Preparando','Enviado','En reparto','Entregado') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `ordenes`
--

INSERT INTO `ordenes` (`Id_orden`, `Id_usuario`, `fecha_orden`, `estado`) VALUES
(1, 2, '2025-03-28', ''),
(2, 3, '2025-03-29', ''),
(3, 4, '2025-03-30', ''),
(4, 5, '2025-03-31', ''),
(5, 1, '2025-04-01', '');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pagos`
--

CREATE TABLE `pagos` (
  `Id_pago` int(11) NOT NULL,
  `Id_orden` int(11) DEFAULT NULL,
  `monto` decimal(10,2) DEFAULT NULL,
  `metodo_pago` enum('Tarjeta','Efectivo','PSE') DEFAULT NULL,
  `fecha_pago` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `pagos`
--

INSERT INTO `pagos` (`Id_pago`, `Id_orden`, `monto`, `metodo_pago`, `fecha_pago`) VALUES
(1, 3, 35.00, 'Tarjeta', '2025-03-28'),
(2, 4, 150.00, 'PSE', '2025-03-29'),
(3, 5, 75.00, 'Efectivo', '2025-03-30'),
(4, 1, 30.00, 'PSE', '2025-03-31'),
(5, 2, 1200.00, 'Tarjeta', '2025-04-01');

--
-- Disparadores `pagos`
--
DELIMITER $$
CREATE TRIGGER `Despues_de_Insertar_en_Pagos` AFTER INSERT ON `pagos` FOR EACH ROW BEGIN
    -- Actualizar el estado de la orden a "Pagada" cuando se realice un pago
    UPDATE ordenes
    SET estado = 'Pagada'
    WHERE Id_orden = NEW.Id_orden;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `Id_producto` int(11) NOT NULL,
  `Id_categoria` int(11) DEFAULT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `descripcion` varchar(100) DEFAULT NULL,
  `precio` int(11) DEFAULT NULL,
  `stock` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`Id_producto`, `Id_categoria`, `nombre`, `descripcion`, `precio`, `stock`) VALUES
(1, 1, 'Laptop', 'Laptop de alto rendimiento - Calificación: 5.00', 1200, 29),
(2, 2, 'Lámpara LED', 'Lámpara de escritorio con luz regulable - Calificación: 3.50', 35, 59),
(3, 3, 'Zapatillas deportivas', 'Zapatillas para correr - Calificación: 5.00', 75, 38),
(4, 4, 'Juguete educativo', 'Rompecabezas para niños - Calificación: 4.50', 25, 97),
(5, 5, 'Shampoo Natural', 'Shampoo sin sulfatos - Calificación: 4.00', 15, 78);

--
-- Disparadores `productos`
--
DELIMITER $$
CREATE TRIGGER `Despues_de_Actualizar_Productos` AFTER UPDATE ON `productos` FOR EACH ROW BEGIN
    IF OLD.precio <> NEW.precio THEN
        INSERT INTO historial_precios (Id_producto, precio_anterior, precio_nuevo, fecha_cambio)
        VALUES (NEW.Id_producto, OLD.precio, NEW.precio, CURDATE());
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `Id_proveedor` int(11) NOT NULL,
  `nombre_proveedor` varchar(100) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL,
  `telefono` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `proveedores`
--

INSERT INTO `proveedores` (`Id_proveedor`, `nombre_proveedor`, `correo`, `telefono`) VALUES
(1, 'Proveedor C', 'contacto@proveedorc.com', '555555555'),
(2, 'Proveedor D', 'contacto@proveedord.com', '666666666'),
(3, 'Proveedor E', 'contacto@proveedore.com', '777777777'),
(4, 'Proveedor F', 'contacto@proveedorf.com', '888888888'),
(5, 'Proveedor G', 'contacto@proveedorg.com', '999999999');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reviews`
--

CREATE TABLE `reviews` (
  `Id_review` int(11) NOT NULL,
  `Id_producto` int(11) DEFAULT NULL,
  `Id_usuario` int(11) DEFAULT NULL,
  `calificacion` decimal(10,2) DEFAULT NULL,
  `comentario` varchar(100) DEFAULT NULL,
  `fecha_review` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `reviews`
--

INSERT INTO `reviews` (`Id_review`, `Id_producto`, `Id_usuario`, `calificacion`, `comentario`, `fecha_review`) VALUES
(1, 2, 3, 3.50, 'Buena lámpara, pero pequeña', '2025-03-28'),
(2, 3, 4, 5.00, 'Las zapatillas son cómodas', '2025-03-29'),
(3, 4, 5, 4.50, 'A mi hijo le encantó', '2025-03-30'),
(4, 5, 1, 4.00, 'Buen shampoo, buen aroma', '2025-03-31'),
(5, 1, 2, 5.00, 'Laptop rápida y eficiente', '2025-04-01');

--
-- Disparadores `reviews`
--
DELIMITER $$
CREATE TRIGGER `Despues_de_Insertar_en_Reviews` AFTER INSERT ON `reviews` FOR EACH ROW BEGIN
    DECLARE promedio DECIMAL(10,2);
    
    -- Calcula el promedio de calificaciones del producto
    SELECT AVG(calificacion) INTO promedio
    FROM reviews
    WHERE Id_producto = NEW.Id_producto;
    
    -- Actualiza el producto con el nuevo promedio
    UPDATE productos
    SET descripcion = CONCAT(descripcion, ' - Calificación: ', promedio)
    WHERE Id_producto = NEW.Id_producto;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sesiones_usuarios`
--

CREATE TABLE `sesiones_usuarios` (
  `Id_sesion` int(11) NOT NULL,
  `Id_usuario` int(11) DEFAULT NULL,
  `token` int(11) DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `Id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `contraseña` varchar(100) DEFAULT NULL,
  `rol` enum('Administrador','Empleado') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`Id_usuario`, `nombre_usuario`, `email`, `contraseña`, `rol`) VALUES
(1, 'empleado2', 'empleado2@example.com', 'clave789', 'Empleado'),
(2, 'cliente1', 'cliente1@example.com', 'clave101', 'Empleado'),
(3, 'cliente2', 'cliente2@example.com', 'clave202', 'Empleado'),
(4, 'admin2', 'admin2@example.com', 'clave303', 'Administrador'),
(5, 'empleado3', 'empleado3@example.com', 'clave404', 'Empleado');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ventas`
--

CREATE TABLE `ventas` (
  `Id_venta` int(11) NOT NULL,
  `Id_cliente` int(11) DEFAULT NULL,
  `Id_producto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio_venta` decimal(10,2) DEFAULT NULL,
  `fecha_venta` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

--
-- Disparadores `ventas`
--
DELIMITER $$
CREATE TRIGGER `Despues_de_insertar_en_ventas` AFTER INSERT ON `ventas` FOR EACH ROW BEGIN
    -- Actualiza el stock del producto restando la cantidad vendida
    UPDATE productos
    SET stock = stock - NEW.cantidad
    WHERE Id_producto = NEW.Id_producto;
END
$$
DELIMITER ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`Id_categoria`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`Id_cliente`);

--
-- Indices de la tabla `compras_proveedores`
--
ALTER TABLE `compras_proveedores`
  ADD PRIMARY KEY (`Id_compra`),
  ADD KEY `Id_proveedor` (`Id_proveedor`),
  ADD KEY `Id_producto` (`Id_producto`);

--
-- Indices de la tabla `configuracion_sitio`
--
ALTER TABLE `configuracion_sitio`
  ADD PRIMARY KEY (`Id_configuracion`);

--
-- Indices de la tabla `cupones`
--
ALTER TABLE `cupones`
  ADD PRIMARY KEY (`Id_cupon`);

--
-- Indices de la tabla `departamentos_empleados`
--
ALTER TABLE `departamentos_empleados`
  ADD PRIMARY KEY (`Id_departamento`);

--
-- Indices de la tabla `detalles_orden`
--
ALTER TABLE `detalles_orden`
  ADD PRIMARY KEY (`Id_detalle`),
  ADD KEY `Id_orden` (`Id_orden`),
  ADD KEY `Id_producto` (`Id_producto`);

--
-- Indices de la tabla `direcciones_usuarios`
--
ALTER TABLE `direcciones_usuarios`
  ADD PRIMARY KEY (`Id_direccion`),
  ADD KEY `Id_usuario` (`Id_usuario`);

--
-- Indices de la tabla `empleados`
--
ALTER TABLE `empleados`
  ADD PRIMARY KEY (`Id_empleado`),
  ADD KEY `Id_departamento` (`Id_departamento`);

--
-- Indices de la tabla `envios`
--
ALTER TABLE `envios`
  ADD PRIMARY KEY (`Id_envio`),
  ADD KEY `Id_orden` (`Id_orden`);

--
-- Indices de la tabla `historial_precios`
--
ALTER TABLE `historial_precios`
  ADD PRIMARY KEY (`Id_historial`),
  ADD KEY `Id_producto` (`Id_producto`);

--
-- Indices de la tabla `imagenes_productos`
--
ALTER TABLE `imagenes_productos`
  ADD PRIMARY KEY (`Id_imagen`),
  ADD KEY `Id_producto` (`Id_producto`);

--
-- Indices de la tabla `impuestos`
--
ALTER TABLE `impuestos`
  ADD PRIMARY KEY (`Id_impuesto`);

--
-- Indices de la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD PRIMARY KEY (`Id_inventario`),
  ADD KEY `Id_producto` (`Id_producto`),
  ADD KEY `Id_proveedor` (`Id_proveedor`);

--
-- Indices de la tabla `logs_sistema`
--
ALTER TABLE `logs_sistema`
  ADD PRIMARY KEY (`Id_log`),
  ADD KEY `Id_usuario` (`Id_usuario`);

--
-- Indices de la tabla `ordenes`
--
ALTER TABLE `ordenes`
  ADD PRIMARY KEY (`Id_orden`),
  ADD KEY `Id_usuario` (`Id_usuario`);

--
-- Indices de la tabla `pagos`
--
ALTER TABLE `pagos`
  ADD PRIMARY KEY (`Id_pago`),
  ADD KEY `Id_orden` (`Id_orden`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`Id_producto`),
  ADD KEY `Id_categoria` (`Id_categoria`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`Id_proveedor`);

--
-- Indices de la tabla `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`Id_review`),
  ADD KEY `Id_producto` (`Id_producto`),
  ADD KEY `Id_usuario` (`Id_usuario`);

--
-- Indices de la tabla `sesiones_usuarios`
--
ALTER TABLE `sesiones_usuarios`
  ADD PRIMARY KEY (`Id_sesion`),
  ADD KEY `Id_usuario` (`Id_usuario`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`Id_usuario`);

--
-- Indices de la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD PRIMARY KEY (`Id_venta`),
  ADD KEY `Id_cliente` (`Id_cliente`),
  ADD KEY `Id_producto` (`Id_producto`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `Id_categoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `Id_cliente` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `compras_proveedores`
--
ALTER TABLE `compras_proveedores`
  MODIFY `Id_compra` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `configuracion_sitio`
--
ALTER TABLE `configuracion_sitio`
  MODIFY `Id_configuracion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `cupones`
--
ALTER TABLE `cupones`
  MODIFY `Id_cupon` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `departamentos_empleados`
--
ALTER TABLE `departamentos_empleados`
  MODIFY `Id_departamento` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalles_orden`
--
ALTER TABLE `detalles_orden`
  MODIFY `Id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `direcciones_usuarios`
--
ALTER TABLE `direcciones_usuarios`
  MODIFY `Id_direccion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `empleados`
--
ALTER TABLE `empleados`
  MODIFY `Id_empleado` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `envios`
--
ALTER TABLE `envios`
  MODIFY `Id_envio` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `historial_precios`
--
ALTER TABLE `historial_precios`
  MODIFY `Id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `imagenes_productos`
--
ALTER TABLE `imagenes_productos`
  MODIFY `Id_imagen` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `impuestos`
--
ALTER TABLE `impuestos`
  MODIFY `Id_impuesto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `inventario`
--
ALTER TABLE `inventario`
  MODIFY `Id_inventario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `logs_sistema`
--
ALTER TABLE `logs_sistema`
  MODIFY `Id_log` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `ordenes`
--
ALTER TABLE `ordenes`
  MODIFY `Id_orden` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `pagos`
--
ALTER TABLE `pagos`
  MODIFY `Id_pago` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `Id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `Id_proveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `reviews`
--
ALTER TABLE `reviews`
  MODIFY `Id_review` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `sesiones_usuarios`
--
ALTER TABLE `sesiones_usuarios`
  MODIFY `Id_sesion` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `Id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `ventas`
--
ALTER TABLE `ventas`
  MODIFY `Id_venta` int(11) NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `compras_proveedores`
--
ALTER TABLE `compras_proveedores`
  ADD CONSTRAINT `compras_proveedores_ibfk_1` FOREIGN KEY (`Id_proveedor`) REFERENCES `proveedores` (`Id_proveedor`),
  ADD CONSTRAINT `compras_proveedores_ibfk_2` FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

--
-- Filtros para la tabla `detalles_orden`
--
ALTER TABLE `detalles_orden`
  ADD CONSTRAINT `detalles_orden_ibfk_1` FOREIGN KEY (`Id_orden`) REFERENCES `ordenes` (`Id_orden`),
  ADD CONSTRAINT `detalles_orden_ibfk_2` FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

--
-- Filtros para la tabla `direcciones_usuarios`
--
ALTER TABLE `direcciones_usuarios`
  ADD CONSTRAINT `direcciones_usuarios_ibfk_1` FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);

--
-- Filtros para la tabla `empleados`
--
ALTER TABLE `empleados`
  ADD CONSTRAINT `empleados_ibfk_1` FOREIGN KEY (`Id_departamento`) REFERENCES `departamentos_empleados` (`Id_departamento`);

--
-- Filtros para la tabla `envios`
--
ALTER TABLE `envios`
  ADD CONSTRAINT `envios_ibfk_1` FOREIGN KEY (`Id_orden`) REFERENCES `ordenes` (`Id_orden`);

--
-- Filtros para la tabla `historial_precios`
--
ALTER TABLE `historial_precios`
  ADD CONSTRAINT `historial_precios_ibfk_1` FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

--
-- Filtros para la tabla `imagenes_productos`
--
ALTER TABLE `imagenes_productos`
  ADD CONSTRAINT `imagenes_productos_ibfk_1` FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

--
-- Filtros para la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD CONSTRAINT `inventario_ibfk_1` FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`),
  ADD CONSTRAINT `inventario_ibfk_2` FOREIGN KEY (`Id_proveedor`) REFERENCES `proveedores` (`Id_proveedor`);

--
-- Filtros para la tabla `logs_sistema`
--
ALTER TABLE `logs_sistema`
  ADD CONSTRAINT `logs_sistema_ibfk_1` FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);

--
-- Filtros para la tabla `ordenes`
--
ALTER TABLE `ordenes`
  ADD CONSTRAINT `ordenes_ibfk_1` FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);

--
-- Filtros para la tabla `pagos`
--
ALTER TABLE `pagos`
  ADD CONSTRAINT `pagos_ibfk_1` FOREIGN KEY (`Id_orden`) REFERENCES `ordenes` (`Id_orden`);

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `productos_ibfk_1` FOREIGN KEY (`Id_categoria`) REFERENCES `categorias` (`Id_categoria`);

--
-- Filtros para la tabla `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`),
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);

--
-- Filtros para la tabla `sesiones_usuarios`
--
ALTER TABLE `sesiones_usuarios`
  ADD CONSTRAINT `sesiones_usuarios_ibfk_1` FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);

--
-- Filtros para la tabla `ventas`
--
ALTER TABLE `ventas`
  ADD CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`Id_cliente`) REFERENCES `clientes` (`Id_cliente`),
  ADD CONSTRAINT `ventas_ibfk_2` FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
