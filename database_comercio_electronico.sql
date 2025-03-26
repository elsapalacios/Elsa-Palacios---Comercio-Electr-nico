CREATE TABLE `usuarios` (
  `Id_usuario` int PRIMARY KEY AUTO_INCREMENT,
  `nombre_usuario` varchar(100),
  `email` varchar(100),
  `contraseña` varchar(100),
  `rol` enum(Administrador,Empleado)
);

CREATE TABLE `categorias` (
  `Id_categoria` int PRIMARY KEY AUTO_INCREMENT,
  `nombre` varchar(100)
);

CREATE TABLE `productos` (
  `Id_producto` int PRIMARY KEY AUTO_INCREMENT,
  `Id_categoria` int,
  `nombre` varchar(100),
  `descripcion` varchar(100),
  `precio` int,
  `stock` int
);

CREATE TABLE `ordenes` (
  `Id_orden` int PRIMARY KEY AUTO_INCREMENT,
  `Id_usuario` int,
  `fecha_orden` date,
  `estado` enum(Preparando,Enviado,En reparto,Entregado)
);

CREATE TABLE `detalles_orden` (
  `Id_detalle` int PRIMARY KEY AUTO_INCREMENT,
  `Id_orden` int,
  `Id_producto` int,
  `cantidad` int,
  `precio_unitario` decimal(10,2)
);

CREATE TABLE `pagos` (
  `Id_pago` int PRIMARY KEY AUTO_INCREMENT,
  `Id_orden` int,
  `monto` decimal(10,2),
  `metodo_pago` enum(Tarjeta,Efectivo,PSE),
  `fecha_pago` date
);

CREATE TABLE `envios` (
  `Id_envio` int PRIMARY KEY AUTO_INCREMENT,
  `Id_orden` int,
  `direccion` varchar(100),
  `ciudad` varchar(100),
  `codigo_postal` varchar(100)
);

CREATE TABLE `reviews` (
  `Id_review` int PRIMARY KEY AUTO_INCREMENT,
  `Id_producto` int,
  `Id_usuario` int,
  `calificacion` decimal(10,2),
  `comentario` varchar(100),
  `fecha_review` date
);

CREATE TABLE `cupones` (
  `Id_cupon` int PRIMARY KEY AUTO_INCREMENT,
  `codigo` varchar(100),
  `descuento` decimal(10,2),
  `fecha_inicio` date,
  `fecha_fin` date
);

CREATE TABLE `imagenes_productos` (
  `Id_imagen` int PRIMARY KEY AUTO_INCREMENT,
  `Id_producto` int,
  `url` varchar(255)
);

CREATE TABLE `direcciones_usuarios` (
  `Id_direccion` int PRIMARY KEY AUTO_INCREMENT,
  `Id_usuario` int,
  `direccion` varchar(100),
  `ciudad` varchar(100),
  `codigo_postal` varchar(100)
);

CREATE TABLE `historial_precios` (
  `Id_historial` int PRIMARY KEY AUTO_INCREMENT,
  `Id_producto` int,
  `precio_anterior` decimal(10,2),
  `precio_nuevo` decimal(10,2),
  `fecha_cambio` date
);

CREATE TABLE `proveedores` (
  `Id_proveedor` int PRIMARY KEY AUTO_INCREMENT,
  `nombre_proveedor` varchar(100),
  `correo` varchar(100),
  `telefono` varchar(100)
);

CREATE TABLE `inventario` (
  `Id_inventario` int PRIMARY KEY AUTO_INCREMENT,
  `Id_producto` int,
  `Id_proveedor` int,
  `cantidad` int,
  `ubicacion` varchar(100)
);

CREATE TABLE `compras_proveedores` (
  `Id_compra` int PRIMARY KEY AUTO_INCREMENT,
  `Id_proveedor` int,
  `Id_producto` int,
  `cantidad` int,
  `precio_compra` decimal(10,2),
  `fecha_compra` date
);

CREATE TABLE `departamentos_empleados` (
  `Id_departamento` int PRIMARY KEY AUTO_INCREMENT,
  `nombre_departamento` varchar(100)
);

CREATE TABLE `empleados` (
  `Id_empleado` int PRIMARY KEY AUTO_INCREMENT,
  `Id_departamento` int,
  `nombre_empleado` varchar(100),
  `cargo` varchar(100),
  `salario` decimal(10,2),
  `fecha_contratacion` date
);

CREATE TABLE `clientes` (
  `Id_cliente` int PRIMARY KEY AUTO_INCREMENT,
  `nombre_cliente` varchar(100),
  `email` varchar(100),
  `telefono` varchar(100),
  `direccion` varchar(100)
);

CREATE TABLE `ventas` (
  `Id_venta` int PRIMARY KEY AUTO_INCREMENT,
  `Id_cliente` int,
  `Id_producto` int,
  `cantidad` int,
  `precio_venta` decimal(10,2),
  `fecha_venta` date
);

CREATE TABLE `impuestos` (
  `Id_impuesto` int PRIMARY KEY AUTO_INCREMENT,
  `nombre_impuesto` varchar(100),
  `tasa` decimal(10,2)
);

CREATE TABLE `configuracion_sitio` (
  `Id_configuracion` int PRIMARY KEY AUTO_INCREMENT,
  `nombre` varchar(100),
  `valor` varchar(100)
);

CREATE TABLE `sesiones_usuarios` (
  `Id_sesion` int PRIMARY KEY AUTO_INCREMENT,
  `Id_usuario` int,
  `token` int,
  `fecha_inicio` date,
  `fecha_fin` date
);

CREATE TABLE `logs_sistema` (
  `Id_log` int PRIMARY KEY AUTO_INCREMENT,
  `Id_usuario` int,
  `accion` varchar(100),
  `tabla_afectada` varchar(100),
  `fecha_hora` datetime
);

ALTER TABLE `productos` ADD FOREIGN KEY (`Id_categoria`) REFERENCES `categorias` (`Id_categoria`);

ALTER TABLE `ordenes` ADD FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);

ALTER TABLE `detalles_orden` ADD FOREIGN KEY (`Id_orden`) REFERENCES `ordenes` (`Id_orden`);

ALTER TABLE `detalles_orden` ADD FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

ALTER TABLE `pagos` ADD FOREIGN KEY (`Id_orden`) REFERENCES `ordenes` (`Id_orden`);

ALTER TABLE `envios` ADD FOREIGN KEY (`Id_orden`) REFERENCES `ordenes` (`Id_orden`);

ALTER TABLE `reviews` ADD FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

ALTER TABLE `reviews` ADD FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);

ALTER TABLE `imagenes_productos` ADD FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

ALTER TABLE `direcciones_usuarios` ADD FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);

ALTER TABLE `historial_precios` ADD FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

ALTER TABLE `inventario` ADD FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

ALTER TABLE `inventario` ADD FOREIGN KEY (`Id_proveedor`) REFERENCES `proveedores` (`Id_proveedor`);

ALTER TABLE `compras_proveedores` ADD FOREIGN KEY (`Id_proveedor`) REFERENCES `proveedores` (`Id_proveedor`);

ALTER TABLE `compras_proveedores` ADD FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

ALTER TABLE `empleados` ADD FOREIGN KEY (`Id_departamento`) REFERENCES `departamentos_empleados` (`Id_departamento`);

ALTER TABLE `ventas` ADD FOREIGN KEY (`Id_cliente`) REFERENCES `clientes` (`Id_cliente`);

ALTER TABLE `ventas` ADD FOREIGN KEY (`Id_producto`) REFERENCES `productos` (`Id_producto`);

ALTER TABLE `sesiones_usuarios` ADD FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);

ALTER TABLE `logs_sistema` ADD FOREIGN KEY (`Id_usuario`) REFERENCES `usuarios` (`Id_usuario`);
