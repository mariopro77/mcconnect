const express = require('express');
const { Pool } = require('pg');
const dotenv = require('dotenv');
const cors = require('cors');
const multer = require('multer');
const path = require('path'); // Importa el módulo path

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
                WHERE e.nombre_empleado ILIKE $1;
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
                INNER JOIN public.estado est ON e.id_estado = est.id_estado;
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
});
