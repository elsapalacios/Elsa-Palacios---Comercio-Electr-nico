<?php
// Conexión a la base de datos
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "database_comercio_electronico";

$conn = new mysqli($servername, $username, $password, $dbname);

// Verificar la conexión
if ($conn->connect_error) {
    die("Conexión fallida: " . $conn->connect_error);
}

$mensaje = ''; // Variable para almacenar el mensaje que se mostrará después de ejecutar el procedimiento

// Comprobar si se ha enviado el formulario
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Obtener el procedimiento elegido
    $procedimiento = $_POST['procedimiento'];
    
    // Ejecutar el procedimiento correspondiente
    if ($procedimiento == 'ActualizarStock') {
        $id_producto = $_POST['id_producto'];
        $cantidad = $_POST['cantidad'];
        
        $stmt = $conn->prepare("CALL ActualizarStock(?, ?)");
        $stmt->bind_param("ii", $id_producto, $cantidad);
        if ($stmt->execute()) {
            $mensaje = "Stock actualizado correctamente.";
        } else {
            $mensaje = "Error al actualizar el stock.";
        }
    }
    
    elseif ($procedimiento == 'AplicarCupon') {
        $id_orden = $_POST['id_orden'];
        $codigo = $_POST['codigo'];
        
        $stmt = $conn->prepare("CALL AplicarCupon(?, ?)");
        $stmt->bind_param("is", $id_orden, $codigo);
        if ($stmt->execute()) {
            $mensaje = "Cupón aplicado correctamente.";
        } else {
            $mensaje = "Error al aplicar el cupón.";
        }
    }

    elseif ($procedimiento == 'CrearOrden') {
        $usuario_id = $_POST['usuario_id'];
        $productos = $_POST['productos'];  // JSON
        
        $stmt = $conn->prepare("CALL CrearOrden(?, ?)");
        $stmt->bind_param("is", $usuario_id, $productos);
        if ($stmt->execute()) {
            $mensaje = "Orden creada correctamente.";
        } else {
            $mensaje = "Error al crear la orden.";
        }
    }

    elseif ($procedimiento == 'GenerarReporteVentas') {
        $fecha_inicio = $_POST['fecha_inicio'];
        $fecha_fin = $_POST['fecha_fin'];
        
        $stmt = $conn->prepare("CALL GenerarReporteVentas(?, ?)");
        $stmt->bind_param("ss", $fecha_inicio, $fecha_fin);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            $mensaje = "<table><tr><th>Producto</th><th>Cantidad Vendida</th><th>Total Ventas</th></tr>";
            while ($row = $result->fetch_assoc()) {
                $mensaje .= "<tr><td>" . $row['producto'] . "</td><td>" . $row['total_cantidad_vendida'] . "</td><td>" . $row['total_ventas'] . "</td></tr>";
            }
            $mensaje .= "</table>";
        } else {
            $mensaje = "Error al generar el reporte de ventas.";
        }
    }

    elseif ($procedimiento == 'ObtenerProductosCategoria') {
        $id_categoria = $_POST['id_categoria'];
        
        $stmt = $conn->prepare("CALL ObtenerProductosCategoria(?)");
        $stmt->bind_param("i", $id_categoria);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            $mensaje = "<table><tr><th>ID Producto</th><th>Nombre</th><th>Precio</th><th>Stock</th></tr>";
            while ($row = $result->fetch_assoc()) {
                $mensaje .= "<tr><td>" . $row['Id_producto'] . "</td><td>" . $row['nombre'] . "</td><td>" . $row['precio'] . "</td><td>" . $row['stock'] . "</td></tr>";
            }
            $mensaje .= "</table>";
        } else {
            $mensaje = "Error al obtener los productos de la categoría.";
        }
    }
}

// Cerrar la conexión
$conn->close();
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ejecutar Procedimientos Almacenados</title>
    <link rel="stylesheet" href="css/pagina_1.css">
</head>
<body>
    <div class="container">
        <h1>Ejecutar Procedimientos Almacenados</h1>

        <form method="POST">
            <label for="procedimiento">Seleccionar Procedimiento:</label>
            <select name="procedimiento" id="procedimiento" required>
                <option value="ActualizarStock">Actualizar Stock</option>
                <option value="AplicarCupon">Aplicar Cupon</option>
                <option value="CrearOrden">Crear Orden</option>
                <option value="GenerarReporteVentas">Generar Reporte de Ventas</option>
                <option value="ObtenerProductosCategoria">Obtener Productos por Categoría</option>
            </select>

            <!-- Campo para ActualizarStock -->
            <div id="ActualizarStockFields" class="fields" style="display:none;">
                <label for="id_producto">ID Producto:</label>
                <input type="number" name="id_producto" id="id_producto">
                <label for="cantidad">Cantidad:</label>
                <input type="number" name="cantidad" id="cantidad">
            </div>

            <!-- Campo para AplicarCupon -->
            <div id="AplicarCuponFields" class="fields" style="display:none;">
                <label for="id_orden">ID Orden:</label>
                <input type="number" name="id_orden" id="id_orden">
                <label for="codigo">Código Cupon:</label>
                <input type="text" name="codigo" id="codigo">
            </div>

            <!-- Campo para CrearOrden -->
            <div id="CrearOrdenFields" class="fields" style="display:none;">
                <label for="usuario_id">ID Usuario:</label>
                <input type="number" name="usuario_id" id="usuario_id">
                <label for="productos">Productos (JSON):</label>
                <textarea name="productos" id="productos"></textarea>
            </div>

            <!-- Campo para GenerarReporteVentas -->
            <div id="GenerarReporteVentasFields" class="fields" style="display:none;">
                <label for="fecha_inicio">Fecha Inicio:</label>
                <input type="date" name="fecha_inicio" id="fecha_inicio">
                <label for="fecha_fin">Fecha Fin:</label>
                <input type="date" name="fecha_fin" id="fecha_fin">
            </div>

            <!-- Campo para ObtenerProductosCategoria -->
            <div id="ObtenerProductosCategoriaFields" class="fields" style="display:none;">
                <label for="id_categoria">ID Categoría:</label>
                <input type="number" name="id_categoria" id="id_categoria">
            </div>

            <button type="submit">Ejecutar Procedimiento</button>
        </form>

        <!-- Mostrar el mensaje del resultado -->
        <div class="resultados">
            <?php
            if ($mensaje) {
                echo "<h3>Resultado:</h3><p>" . $mensaje . "</p>";
            }
            ?>
        </div>
    </div>

    <script>
        // Mostrar los campos de acuerdo al procedimiento seleccionado
        document.getElementById('procedimiento').addEventListener('change', function() {
            let selectedProcedure = this.value;
            document.querySelectorAll('.fields').forEach(function(div) {
                div.style.display = 'none';  // Ocultar todos los campos
            });
            document.getElementById(selectedProcedure + 'Fields').style.display = 'block';  // Mostrar campos correspondientes
        });

        // Mostrar el campo por defecto al cargar la página
        document.getElementById('procedimiento').dispatchEvent(new Event('change'));
    </script>
</body>
</html>

