const express = require('express');
const { Pool } = require('pg');
const dotenv = require('dotenv');
const cors = require('cors');
const multer = require('multer');
const path = require('path'); // Importa el módulo path
const QRCode = require('qrcode');

const app = express();

app.use(cors());


// Configurar dotenv para cargar el archivo .env desde la ruta específica
dotenv.config({ path: './.env' });

app.use(express.json());

// Servir archivos estáticos desde 'public/'
app.use('/public', express.static(path.join(__dirname, 'public')));

const PORT = process.env.PORT || 4000;

// Configuración de multer para la subida de imágenes
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'public'); // Carpeta donde se guardarán las imágenes
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname)); // Usa path.extname
    }
});
const upload = multer({ storage: storage });

// Crear un pool de conexiones utilizando las variables de entorno
const pool = new Pool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT,
});



// Ruta para subir una imagen
app.post('/api/upload-image', upload.single('file'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ message: 'No se ha subido ningún archivo.' });
    }

    // Construye la URL de la imagen
    const imageUrl = `/public/${req.file.filename}`;

    res.status(201).json({ name_saved: req.file.filename, url: imageUrl });


});

// Ruta para obtener los departamentos
app.get('/api/departamentos', async (req, res) => {
    try {
        const query = 'SELECT * FROM public.departamento';
        const result = await pool.query(query);
        res.status(200).json(result.rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Error al obtener los departamentos' });
    }
});

// Ruta para obtener divisiones
app.get('/api/divisiones', async (req, res) => {
    try {
        const query = 'SELECT * FROM public.division';
        const result = await pool.query(query);
        res.status(200).json(result.rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Error al obtener las divisiones' });
    }
});


// Ruta para obtener detalles de una división específica
app.get('/api/division/:id', async (req, res) => {
    const divisionId = req.params.id;

    try {
        const query = 'SELECT ubicacion, web, instagram FROM division WHERE id_division = $1';
        const result = await pool.query(query, [divisionId]);

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'División no encontrada' });
        }

        res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error('Error al obtener la división:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});




// Ruta para obtener todos los empleados
app.get('/api/verempleado', async (req, res) => {
    const search = req.query.search;

    try {
        let query;
        let values = [];

        if (search) {
            query = `
                SELECT 
                    e.id_empleado, 
                    e.nombre_empleado, 
                    e.telefono_empleado, 
                    e.flota_empleado, 
                    e.extension_empleado, 
                    e.qr_empleado, 
                    e.fecha_creacion_empleado, 
                    e.imagen_empleado, 
                    e.web_empleado, 
                    e.correo_empleado,
                    e.posicion_empleado,
                    d.departamento, 
                    e.id_division,  
                    div.division,          
                    div.instagram,
                    div.ubicacion,
                    div.web AS web,
                    est.estado            
                FROM public.empleado e 
                INNER JOIN public.departamento d ON e.id_departamento = d.id_departamento 
                INNER JOIN public.division div ON e.id_division = div.id_division 
                INNER JOIN public.estado est ON e.id_estado = est.id_estado
                WHERE e.nombre_empleado ILIKE $1
                ORDER BY e.id_empleado;
            `;
            values = [`%${search}%`];
        } else {
            query = `
                SELECT 
                    e.id_empleado, 
                    e.nombre_empleado, 
                    e.telefono_empleado, 
                    e.flota_empleado, 
                    e.extension_empleado, 
                    e.qr_empleado, 
                    e.fecha_creacion_empleado, 
                    e.imagen_empleado, 
                    e.web_empleado, 
                    e.correo_empleado,
                    e.posicion_empleado,
                    e.id_division,
                    d.departamento,   
                    div.division,          
                    div.instagram,
                    div.ubicacion,
                    div.web AS web,
                    est.estado            
                FROM public.empleado e 
                INNER JOIN public.departamento d ON e.id_departamento = d.id_departamento 
                INNER JOIN public.division div ON e.id_division = div.id_division 
                INNER JOIN public.estado est ON e.id_estado = est.id_estado
                ORDER BY e.id_empleado;
            `;
        }

        const result = await pool.query(query, values);
        res.status(200).json(result.rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Error al obtener los empleados' });
    }
});


// Ruta para agregar un nuevo empleado
app.post('/api/agregarempleado', async (req, res) => {
    const {
        nombre_empleado,
        telefono_empleado,
        flota_empleado,
        extension_empleado,
        qr_empleado,
        fecha_creacion_empleado,
        web_empleado,
        posicion_empleado,
        departamento,
        id_division,
        imagen_empleado,
        correo_empleado
    } = req.body;

    try {
        // Obtener el id_departamento correspondiente al nombre_departamento
        const departamentoQuery = 'SELECT id_departamento FROM departamento WHERE departamento = $1';
        const departamentoResult = await pool.query(departamentoQuery, [departamento]);

        if (departamentoResult.rowCount === 0) {
            return res.status(400).json({ error: 'Nombre de departamento no válido' });
        }

        const id_departamento = departamentoResult.rows[0].id_departamento;

        // Obtener el id_estado correspondiente a 'Activo'
        const estadoQuery = "SELECT id_estado FROM estado WHERE estado = 'Activo'";
        const estadoResult = await pool.query(estadoQuery);

        if (estadoResult.rowCount === 0) {
            return res.status(500).json({ error: "Estado 'Activo' no encontrado en la base de datos" });
        }

        const id_estado = estadoResult.rows[0].id_estado;

        // Consulta para insertar un nuevo empleado
        const query = `
            INSERT INTO public.empleado 
            (
                nombre_empleado, 
                telefono_empleado, 
                flota_empleado, 
                extension_empleado, 
                qr_empleado, 
                fecha_creacion_empleado, 
                imagen_empleado, 
                web_empleado, 
                posicion_empleado, 
                correo_empleado, 
                id_departamento, 
                id_division, 
                id_estado
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
            RETURNING id_empleado;
        `;

        const values = [
            nombre_empleado,
            telefono_empleado || null,
            flota_empleado || null,          // $3
            extension_empleado || null,      // $4
            qr_empleado || null,             // $5
            fecha_creacion_empleado || null, // $6
            imagen_empleado || null,         // $7
            web_empleado || null,            // $8
            posicion_empleado || null,       // $9
            correo_empleado || null,         // $10
            parseInt(id_departamento),       // $11
            id_division,                     // $12
            id_estado                        // $13
        ];

        const result = await pool.query(query, values);
        const newEmpleadoId = result.rows[0].id_empleado;

        res.status(201).json({ message: 'Empleado agregado exitosamente', empleadoId: newEmpleadoId });
    } catch (e) {
        console.error('Error al agregar empleado:', e);
        res.status(500).json({ error: 'Error al agregar el empleado' });
    }
});


//Ruta para actualizar empleado
app.put('/api/actualizarempleado/:id', async (req, res) => {
    console.log('Método:', req.method);
    const empleadoId = req.params.id;
    const {
        correo_empleado,
        departamento,
        estado,
        extension_empleado,
        fecha_creacion_empleado,
        flota_empleado,
        imagen_empleado,
        instagram,
        nombre_empleado,
        posicion_empleado,
        qr_empleado,
        telefono_empleado,
        ubicacion,
        division,
        id_division,
        web
    } = req.body;

    try {
        let campos = [];
        let valores = [];
        let contador = 1;

        if (nombre_empleado !== undefined) {
            campos.push(`nombre_empleado = $${contador}`);
            valores.push(nombre_empleado);
            contador++;
        }

        if (correo_empleado !== undefined) {
            campos.push(`correo_empleado = $${contador}`);
            valores.push(correo_empleado);
            contador++;
        }

        if (departamento !== undefined) {

            const departamentoQuery = 'SELECT id_departamento FROM departamento WHERE departamento = $1';
            const departamentoResult = await pool.query(departamentoQuery, [departamento]);

            if (departamentoResult.rowCount === 0) {
                return res.status(400).json({ error: 'Nombre de departamento no válido' });
            }

            const id_departamento = departamentoResult.rows[0].id_departamento; // Corregido

            campos.push(`id_departamento = $${contador}`);
            valores.push(id_departamento);
            contador++;
        }

        if (id_division) {
            campos.push(`id_division = $${contador}`);
            valores.push(id_division);
            contador++;
        }

        if (estado !== undefined) {

            const estadoQuery = "SELECT id_estado FROM estado WHERE estado = $1";
            const estadoResult = await pool.query(estadoQuery, [estado]);

            if (estadoResult.rowCount === 0) {
                return res.status(500).json({ error: "Estado 'Activo' no encontrado en la base de datos" });
            }

            const id_estado = estadoResult.rows[0].id_estado;
            campos.push(`id_estado = $${contador}`);
            valores.push(id_estado);
            contador++;
        }

        if (extension_empleado) {
            campos.push(`extension_empleado = $${contador}`);
            valores.push(extension_empleado);
            contador++;
        }

        if (fecha_creacion_empleado) {
            campos.push(`fecha_creacion_empleado = $${contador}`);
            valores.push(fecha_creacion_empleado);
            contador++;
        }

        if (flota_empleado) {
            campos.push(`flota_empleado = $${contador}`);
            valores.push(flota_empleado);
            contador++;
        }

        if (imagen_empleado) {
            campos.push(`imagen_empleado = $${contador}`);
            valores.push(imagen_empleado);
            contador++;
        }


        if (posicion_empleado) {
            campos.push(`posicion_empleado = $${contador}`);
            valores.push(posicion_empleado);
            contador++;
        }

        if (qr_empleado !== undefined) {
            campos.push(`qr_empleado = $${contador}`);
            valores.push(qr_empleado);
            contador++;
        }

        if (telefono_empleado !== undefined) {
            campos.push(`telefono_empleado = $${contador}`);
            valores.push(telefono_empleado);
            contador++;
        }


        if (campos.length === 0) {
            return res.status(400).json({ error: 'No se proporcionaron campos para actualizar' });
        }

        const query = `UPDATE empleado SET ${campos.join(', ')} WHERE id_empleado = $${contador} RETURNING *`;
        valores.push(empleadoId);

        const resultado = await pool.query(query, valores);

        if (resultado.rowCount === 0) {
            return res.status(404).json({ error: 'Empleado no encontrado' });
        }

        res.status(200).json({
            mensaje: 'Empleado actualizado exitosamente',
            empleado: resultado.rows[0]
        });
    } catch (error) {
        console.error('Error al actualizar el empleado:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

//Obtener informacion de un empleado por su nombre
function obtenerEmpleadoPorId(nombre, callback) {
    const query = 'SELECT * FROM empleado WHERE nombre_empleado = $1'; // Usamos parámetros de consulta con $1
    pool.query(query, [nombre], (err, result) => {
        if (err) {
            return callback(err);
        }

        // Verifica si el empleado fue encontrado
        if (result.rows.length > 0) {
            const empleado = result.rows[0];
            callback(null, empleado);
        } else {
            callback(new Error('Empleado no encontrado'));
        }
    });
}

//Obtener nombre del departamento por Id
function obtenerDepartamentoPorId(id_departamento, callback) {
    const query = 'SELECT departamento FROM departamento WHERE id_departamento = $1';

    pool.query(query, [id_departamento], (err, result) => {
        if (err) {
            return callback(err);
        }

        if (result.rows.length > 0) {
            const departamento = result.rows[0].departamento;
            callback(null, departamento);
        } else {
            callback(new Error('Departamento no encontrado'));
        }
    });
}

function obtenerWebPorId(id_division, callback) {
    const query = 'SELECT web FROM division WHERE id_division = $1';

    pool.query(query, [id_division], (err, result) => {
        if (err) {
            return callback(err);
        }

        if (result.rows.length > 0) {
            const web = result.rows[0].web;
            callback(null, web);
        } else {
            callback(new Error('Departamento no encontrado'));
        }
    });
}

function obtenerUbicacionPorId(id_division, callback) {
    const query = 'SELECT ubicacion FROM division WHERE id_division = $1';

    pool.query(query, [id_division], (err, result) => {
        if (err) {
            return callback(err);
        }

        if (result.rows.length > 0) {
            const ubicacion = result.rows[0].ubicacion;
            callback(null, ubicacion);
        } else {
            callback(new Error('Departamento no encontrado'));
        }
    });
}



app.get('/contacto/:id', (req, res) => {
    const empleadoId = req.params.id;

    obtenerEmpleadoPorId(empleadoId, (err, empleado) => {
        if (err) {
            return res.status(500).send('Error al obtener la información del empleado');
        }

        // Obtiene el nombre del departamento basado en el id_departamento del empleado
        obtenerDepartamentoPorId(empleado.id_departamento, (err, nombre_departamento) => {
            if (err) {
                return res.status(500).send('Error al obtener el departamento');
            }

            // Obtiene la web y la ubicación basadas en id_division
            obtenerWebPorId(empleado.id_division, (err, web) => {
                if (err) {
                    return res.status(500).send('Error al obtener la web');
                }

                obtenerUbicacionPorId(empleado.id_division, (err, ubicacion) => {
                    if (err) {
                        return res.status(500).send('Error al obtener la ubicación');
                    }

                    function obtenerGradientePorDivision(id_division) {
                        switch (id_division) {
                            case 1:
                                return 'background-image: linear-gradient(to right, #17A2B8, #117585, #0D5F6C, #0A4852)';
                            case 2:
                                return 'background-image: linear-gradient(to right, #47601D, #6D932C, #80AD33, #93C63B)';
                            case 3:
                                return 'background-image: linear-gradient(to right, #083B8E, #05265B, #041B42, #021128)';
                            case 4:
                                return 'background-image: linear-gradient(to right, #093859, #0F598C, #47886C, #7FB74B)';
                            case 5:
                                return 'background-image: linear-gradient(to right, #17A2B8, #117585, #0D5F6C, #0A4852)';
                            case 6:
                                return 'background-image: linear-gradient(to right, #083B8E, #05265B, #041B42, #021128)';
                            default:
                                return 'background-image: linear-gradient(to right, #17A2B8, #117585, #0D5F6C, #0A4852)';
                        }
                    }

                    function obtenerImagenPorDivision(id_division) {
                        let imageUrl = '';
                        let size = { width: 100, height: 100 }; // Tamaño predeterminado

                        switch (id_division) {
                            case 1:
                                imageUrl = '/public/Logos/logo2.png';
                                size = { width: 120, height: 120 };
                                break;
                            case 2:
                                imageUrl = '/public/Logos/Concilialogo.png';
                                size = { width: 50, height: 50 };
                                break;
                            case 3:
                                imageUrl = '/public/Logos/figiboxSomos.jpeg';
                                size = { width: 120, height: 120 };
                                break;
                            case 4:
                                imageUrl = '/public/Logos/high-performance.png';
                                size = { width: 70, height: 70 };
                                break;
                            case 5:
                                imageUrl = '/public/Logos/logo2.png';
                                size = { width: 70, height: 70 };
                                break;
                            case 6:
                                imageUrl = '/public/Logos/figiboxSomos.jpeg';
                                size = { width: 70, height: 70 };
                                break;
                            default:
                                imageUrl = '/public/Logos/logo2.png';
                                size = { width: 100, height: 100 };
                                break;
                        }

                        return { url: imageUrl, width: size.width, height: size.height };
                    }

                    function generarDetallesEmpleado(empleado) {
                        let detalles = '';
                        if (empleado.correo_empleado) {
                            detalles += `
                            <a href="mailto:${empleado.correo_empleado}">
                                <div class="h-14 rounded-lg shadow-lg p-4 bg-white hover:bg-white/85 text-black flex items-center">
                                    <i class="fas fa-envelope text-blue-500 fa-xl mr-3"></i>
                                    <p class="text-lg">Correo electrónico</p>
                                </div>
                            </a>`;
                        }

                        if (empleado.telefono_empleado) {
                            const telefonoLimpio = empleado.telefono_empleado.replace(/\D/g, '');
                            detalles += `
                            <a href="tel:${telefonoLimpio}">
                                <div class="h-14 rounded-lg shadow-lg p-4 bg-white hover:bg-white/85 text-black flex items-center">
                                    <i class="fas fa-phone-alt text-green-500 mr-3 fa-lg"></i>
                                    <p class="text-lg">Teléfono</p>
                                </div>
                            </a>`;
                        }

                        if (empleado.flota_empleado) {
                            const numeroFlota = empleado.flota_empleado.replace(/\D/g, '');
                            detalles += `
                            <a href="https://wa.me/${numeroFlota}" target="_blank">
                                <div class="h-14 rounded-lg shadow-lg p-4 bg-white hover:bg-white/85 text-black flex items-center">
                                    <i class="fab fa-whatsapp text-green-500 mr-3 fa-xl"></i>
                                    <p class="text-lg">Whatsapp</p>
                                </div>
                            </a>`;
                        }

                        return detalles;
                    }
    

            // Construye el HTML con la información del empleado y TailwindCSS
            const html = `
           <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contacto de ${empleado.nombre_empleado}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/qr-code-styling/lib/qr-code-styling.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
</head>
<body class="bg-gray-100">
    <div class=" p-2 sm:p-8">
        <div class="relative bg-white shadow-md rounded-lg p-6 container-none sm:container mx-0 sm:mx-auto max-w-6xl" style="${obtenerGradientePorDivision(empleado.id_division)}">
            <div class="w-full flex flex-row justify-between items-center">
                <button id="qr-button" class="hover:bg-black/30 hover:backdrop-blur-lg rounded-full p-2 text-center h-14 w-14">
                    <img class="" src="/public/Iconos/scan_qr.png" />
                </button>
                <!-- Overlay y Modal para el código QR -->
                <div id="modal-overlay" class="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center z-50" style="display: none;">
                 <button id="close-modal" class="right-2 top-2 fixed mt-4 transition ease-in-out delay-150 hover:scale-110 text-red-500 rounded-lg h-12 w-24 p-2 flex items-center justify-center"><img class="h-8 w-8" src="/public/Iconos/Close.png" /></button>
                    <div class="bg-white p-6 rounded-lg shadow-lg relative">
                        <div id="qr-container"></div>
                    </div>
                </div>

                <!-- Logo de la División -->
                <div class="rounded-lg mx-auto bg-white p-2">
                    <img class="object-cover" src="${obtenerImagenPorDivision(empleado.id_division).url}" width="${obtenerImagenPorDivision(empleado.id_division).width}" height="${obtenerImagenPorDivision(empleado.id_division).height}" alt="Logo de la División" />
                </div>

                <!-- Botón de compartir -->
                <button id="morebutton" class="hover:bg-black/30 hover:backdrop-blur-lg rounded-full p-2 text-center h-12 w-12">
                    <img src="/public/Iconos/Dots.png" alt="Share Icon" />
                </button>
                <!-- Contenedor del menú adicional -->
                <div id="more-menu" class="absolute right-2 top-6 bg-white rounded-lg shadow-lg p-4" style="display: none;">
                    <button id="close-more-menu" class="right-0 top-1 flex absolute items-center rounded transition ease-in-out delay-150 hover:scale-125">
                            <img src="/public/Iconos/Close.png" alt="Compartir" class="h-6 w-6 mr-2" />
                    </button>
                    <button id="shareButton" class="flex items-center p-2 hover:bg-gray-200 rounded mt-4">
                        <img src="/public/Iconos/share.png" alt="Compartir" class="h-6 w-6 mr-2" />
                        Compartir
                    </button>
                    <button id="locationButton" class="flex items-center p-2 hover:bg-gray-200 rounded">
                        <img src="/public/Iconos/location.png" alt="Ubicación" class="h-6 w-6 mr-2" />
                        Ubicación
                    </button>
                    <button id="websiteButton" class="flex items-center p-2 hover:bg-gray-200 rounded">
                        <img src="/public/Iconos/website.png" alt="Página Web" class="h-6 w-6 mr-2" />
                        Página Web
                    </button>
                </div>
            </div>

            <!-- Imagen del Empleado -->
            <div class="w-full flex justify-center mx-auto mt-10">
                <img class="object-fill rounded-full overflow-hidden h-48 w-48" alt="Imagen-Imagen" src="${empleado.imagen_empleado ? empleado.imagen_empleado : '/public/Iconos/UserIcon.png'}" />
            </div>
            <div class="pt-5">
                <h1 class="text-3xl font-bold mb-4 text-white text-center">${empleado.nombre_empleado}</h1>
                <p class="text-lg text-white text-center">${nombre_departamento}</p>
                <p class="text-md text-white text-center mt-2r">${empleado.posicion_empleado}</p>
            </div>

            <!-- Botón de descarga -->
            <div class="flex justify-center mt-8">
                <button id="downloadButton" class="hover:bg-white/75 hover:backdrop-blur-lg rounded-lg p-2 text-center justify-center flex flex-row gap-2 items-center bg-white/50 w-24">
                    <img class="h-8 w-8" src="/public/Iconos/download.png" />
                </button>
            </div>

            <!-- Detalles del Empleado -->
            <div class="grid grid-flow-row auto-rows-max grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-8 mx-auto">
                ${generarDetallesEmpleado(empleado)}
            </div>
        </div>
    </div>

    <script>
        // Variables y funciones necesarias
        const empleado = {
            id_division: ${empleado.id_division},
            nombre_empleado: "${empleado.nombre_empleado}",
            telefono_empleado: "${empleado.telefono_empleado}"
        };

        const obtenerColorPorDivision = function(id_division) {
            switch (id_division) {
                case 1:
                    return '#80AD33';
                case 2:
                    return '#80AD33';
                case 3:
                    return '#083B8E';
                case 4:
                    return '#47886C';
                default:
                    return '#80AD33';
            }
        };

        const obtenerLogo = function(id_division) {
            switch (id_division) {
                case 1:
                    return '/public/Logos/Logo_mc.png';
                case 2:
                    return '/public/Logos/Concilialogo.png';
                case 3:
                    return '/public/Logos/figiboxSomos.jpeg';
                case 4:
                    return '/public/Logos/high-performance.png';
                default:
                    return '/public/Logos/Logo_mc.png';
            }
        };

        document.addEventListener('DOMContentLoaded', function () {
            const qrButton = document.getElementById('qr-button');
            const qrContainer = document.getElementById('qr-container');
            const modalOverlay = document.getElementById('modal-overlay');
            const closeModalButton = document.getElementById('close-modal');
            const downloadButton = document.getElementById('downloadButton');
            const moreButton = document.getElementById('morebutton');
            const moreMenu = document.getElementById('more-menu');
            let qrVisible = false;
            let moreVisible = false;

            // Obtiene el color de los dots basado en la división
            const colorDots = obtenerColorPorDivision(empleado.id_division);
            const Logo = obtenerLogo(empleado.id_division);

            // Configura el código QR
            const qrCode = new QRCodeStyling({
                width: 300,
                height: 300,
                data: window.location.href,
                image: Logo,
                dotsOptions: {
                    color: colorDots,
                    type: "rounded"
                },
                cornersSquareOptions: {
                    color: "#041B40",
                    type: "dot"
                },
                cornersDotOptions: {
                    color: "#39A4EC",
                    type: "dot"
                },
                backgroundOptions: {
                    color: "transparent",
                },
                imageOptions: {
                    crossOrigin: "anonymous",
                    margin: 5
                }
            });

            const closeMoreMenuButton = document.getElementById('close-more-menu');
                closeMoreMenuButton.addEventListener('click', function (event) {
                    event.stopPropagation(); // Evita que el evento se propague al documento
                    moreMenu.style.display = 'none'; // Cierra el menú
                });

            qrButton.addEventListener('click', function () {
                if (!qrVisible) {
                    qrContainer.innerHTML = '';
                    qrCode.append(qrContainer);
                    modalOverlay.style.display = 'flex';
                    qrVisible = true;
                }
            });

            // Lógica para compartir
            if (navigator.share) {
                shareButton.addEventListener('click', async () => {
                    try {
                        await navigator.share({
                            title: "Perfil de ${empleado.nombre_empleado}",
                            text: "Consulta el perfil de ${empleado.nombre_empleado} en nuestra empresa.",
                            url: window.location.href
                        });
                        console.log('Contenido compartido exitosamente');
                    } catch (error) {
                        console.error('Error al compartir:', error);
                    }
                });
            } else {
                shareButton.addEventListener('click', () => {
                    alert('La función de compartir no está disponible en este navegador.');
                });
            }

            // Cerrar el modal
            closeModalButton.addEventListener('click', function () {
                modalOverlay.style.display = 'none';
                qrVisible = false;
            });

            downloadButton.addEventListener('click', function (){
                var telefono_empleado = empleado.telefono_empleado;
                var nombre_empleado = empleado.nombre_empleado

                var vcard = "BEGIN:VCARD\\n" +
            "VERSION:4.0\\n" +
            "FN:" + nombre_empleado + "\\n" +
            "TEL;TYPE=CELL:" + telefono_empleado + "\\n" +
            "END:VCARD";

             var blob = new Blob([vcard], { type: "text/vcard;charset=utf-8" });
                var url = URL.createObjectURL(blob);

                var a = document.createElement('a');
                a.href = url;
                a.download = nombre_empleado + ".vcf";
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
            });

             // Alternar la visibilidad del menú al hacer clic en el botón "More"
moreButton.addEventListener('click', function (event) {
    event.stopPropagation(); // Evita que el evento se propague al documento
    if (moreMenu.style.display === 'none' || moreMenu.style.display === '') {
        moreMenu.style.display = 'block';
    } else {
        moreMenu.style.display = 'none';
    }
});


            // Ocultar el menú al hacer clic fuera de él
            document.addEventListener('click', function (event) {
                const isClickInside = moreButton.contains(event.target) || moreMenu.contains(event.target);
                if (!isClickInside) {
                    moreMenu.style.display = 'none';
                }
            });

            // Añadir funcionalidad a los botones dentro del menú
            // Botón de ubicación
            const locationButton = document.getElementById('locationButton');
            locationButton.addEventListener('click', function () {
                // Abre Google Maps con una dirección específica
                window.open('https://www.google.com/maps?q=${ubicacion}', '_blank');
            });

            // Botón de página web
            const websiteButton = document.getElementById('websiteButton');
            websiteButton.addEventListener('click', function () {
                // Abre la página web deseada
                window.open('https://${web}', '_blank');
            });

                    
                    });
    </script>
</body>
</html>

        `;
        

            // Devuelve el HTML como respuesta
                res.send(html);
            });
        });
    });
    });
});




// Manejo de errores de Multer (solo para upload-image)
app.use((err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        // Errores de Multer
        res.status(400).json({ error: err.message });
    } else if (err) {
        // Otros errores
        res.status(400).json({ error: err.message });
    } else {
        next();
    }
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
})
