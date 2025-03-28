<?php
$conexion = new mysqli("localhost", "root", "", "database_comercio_electronico");
if ($conexion->connect_error) {
    die("Error de conexión: " . $conexion->connect_error);
}

$resultado_funcion = "";
if (isset($_POST['ejecutar_funcion'])) {
    $funcion = $_POST['funcion'];
    
    switch ($funcion) {
        case 'Aplicar_Impuesto':
            if (!empty($_POST['id']) && !empty($_POST['valor'])) {
                $id = intval($_POST['id']); 
                $valor = floatval($_POST['valor']); 
                $query = "SELECT Aplicar_Impuesto($valor, $id) AS resultado";
            } else {
                die("Error: Se requieren dos parámetros (valor e ID).");
            }
            break;
            case 'CalcularTotalOrden':
                if (!empty($_POST['id'])) {
                    $id = intval($_POST['id']); 
                    $query = "SELECT CalcularTotalOrden($id) AS resultado";
                } else {
                    die("Error: Se requiere un ID de orden.");
                }
                break;
            
        case 'Obtener_Nombre_Usuario':
            if (!empty($_POST['id'])) {
                $id = intval($_POST['id']);
                $query = "SELECT Obtener_Nombre_Usuario($id) AS resultado";
            } else {
                die("Error: Se requiere un ID.");
            }
            break;
        default:
            die("Función no válida.");
    }
    
    $result = $conexion->query($query);
    if ($result) {
        if ($row = $result->fetch_assoc()) {
            $resultado_funcion = $row['resultado'];
        }
    } else {
        die("Error en la consulta: " . $conexion->error);
    }
}

$conexion->close();
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ejecutar Funciones</title>
    <link rel="stylesheet" href="css/pagina_2.css">
</head>
<body>
    <div class="container">
        <h2>Ejecutar Función</h2>
        <form method="post">
            <select name="funcion" required>
                <option value="Aplicar_Impuesto">Aplicar Impuesto</option>
                <option value="CalcularTotalOrden">Calcular Total Orden</option>
                <option value="Obtener_Nombre_Usuario">Obtener Nombre Usuario</option>
            </select>
            <input type="text" name="id" placeholder="Ingrese ID">
            <input type="text" name="valor" placeholder="Ingrese Valor">
            <button type="submit" name="ejecutar_funcion">Ejecutar</button>
            <a href="index.php">Regresar</a>
        </form>
        
        <?php if ($resultado_funcion !== ""): ?>
            <h3>Resultado: <?= $resultado_funcion ?></h3>
        <?php endif; ?>
    </div>
</body>
</html>
