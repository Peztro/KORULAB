# 🧩 Guía de Componentes de KORULAB

## 📚 Índice

1. [Widgets Animados](#widgets-animados)
2. [Tarjetas y Contenedores](#tarjetas-y-contenedores)
3. [Inputs y Formularios](#inputs-y-formularios)
4. [Barras de Progreso](#barras-de-progreso)
5. [Componentes de Navegación](#componentes-de-navegación)
6. [Componentes Especiales](#componentes-especiales)
7. [Ejemplos Prácticos](#ejemplos-prácticos)

---

## 🎬 Widgets Animados

Los widgets animados proporcionan transiciones suaves y efectos visuales profesionales.

### AnimatedCard

Tarjeta con animaciones de fade, slide y elevación al hover.

```dart
AnimatedCard(
  child: ListTile(
    title: Text('Mi Tarjeta'),
    subtitle: Text('Contenido aquí'),
  ),
  delayDuration: Duration(milliseconds: 200),
  onTap: () => print('Tarjeta presionada'),
)
```

**Propiedades:**
- `child`: Widget a animar
- `delayDuration`: Retraso antes de iniciar animación
- `onTap`: Callback al presionar
- `backgroundColor`: Color de fondo (por defecto blanco)
- `elevation`: Sombra de la tarjeta

**Efecto:**
```
Antes: Tarjeta opaca, posición original
  ↓ (200ms)
Después: Fade-in + slide-up + sombra
```

### AnimatedElevatedButton

Botón con escala y transición de color.

```dart
AnimatedElevatedButton(
  label: 'Presioname',
  onPressed: () => print('Botón presionado'),
  backgroundColor: Colors.blue,
  elevation: 8,
)
```

**Propiedades:**
- `label`: Texto del botón
- `onPressed`: Callback de presión
- `backgroundColor`: Color de fondo
- `foregroundColor`: Color del texto
- `elevation`: Altura de sombra

**Efecto:**
```
Hover: Escala 1.0 → 1.05
Press: Escala 1.05 → 0.95 → 1.0
```

### AnimatedListView

Lista con entrada escalonada de items.

```dart
AnimatedListView(
  items: [
    ListTile(title: Text('Item 1')),
    ListTile(title: Text('Item 2')),
    ListTile(title: Text('Item 3')),
  ],
  itemDelay: Duration(milliseconds: 100),
  scrollDirection: Axis.vertical,
)
```

**Propiedades:**
- `items`: Lista de widgets
- `itemDelay`: Retraso entre cada item
- `scrollDirection`: Vertical u horizontal
- `physics`: Comportamiento del scroll

**Efecto:**
```
Item 1: Aparece en T=0ms
Item 2: Aparece en T=100ms
Item 3: Aparece en T=200ms
```

### AnimatedIcon

Icono con rotación y cambio de escala.

```dart
AnimatedIcon(
  icon: Icons.favorite,
  isActive: isFavorite,
  onPressed: () {
    setState(() => isFavorite = !isFavorite);
  },
  activeColor: Colors.red,
  inactiveColor: Colors.grey,
)
```

**Propiedades:**
- `icon`: Icono a animar
- `isActive`: Estado actual
- `onPressed`: Callback
- `activeColor`: Color cuando activo
- `inactiveColor`: Color cuando inactivo

**Efecto:**
```
Inactivo → Activo: Escala 1.0 → 1.2 + Cambio de color
```

### ShimmerLoading

Efecto de carga tipo Shimmer (brillo).

```dart
ShimmerLoading(
  isLoading: true,
  child: Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(height: 20, color: Colors.grey),
          SizedBox(height: 10),
          Container(height: 20, color: Colors.grey),
        ],
      ),
    ),
  ),
)
```

**Propiedades:**
- `isLoading`: Si mostrar efecto
- `child`: Widget a mostrar

**Efecto:**
```
Gradiente que se mueve de izq a der
Simula carga de contenido
```

### FadePageRoute

Transición de página con fade (desvanecimiento).

```dart
Navigator.push(
  context,
  FadePageRoute(
    page: MiPagina(),
    duration: Duration(milliseconds: 300),
  ),
);
```

**Propiedades:**
- `page`: Página a mostrar
- `duration`: Duración de transición

**Efecto:**
```
Pantalla anterior: Opacidad 1.0 → 0.0 (fade out)
Pantalla nueva: Opacidad 0.0 → 1.0 (fade in)
```

### SlidePageRoute

Transición de página con deslizamiento.

```dart
Navigator.push(
  context,
  SlidePageRoute(
    page: MiPagina(),
    duration: Duration(milliseconds: 400),
    direction: SlideDirection.rightToLeft,
  ),
);
```

**Propiedades:**
- `page`: Página a mostrar
- `duration`: Duración
- `direction`: Dirección del deslizamiento

**Efectos:**
```
rightToLeft: Nueva pant entra de der a izq
leftToRight: Nueva pant entra de izq a der
upToDown: Nueva pant entra de abajo
downToUp: Nueva pant entra de arriba
```

### AnimatedItemEntry

Widget que anima entrada de item individual.

```dart
AnimatedItemEntry(
  child: ListTile(title: Text('Mi Item')),
  delay: Duration(milliseconds: 300),
  duration: Duration(milliseconds: 500),
)
```

**Propiedades:**
- `child`: Widget a animar
- `delay`: Retraso antes de empezar
- `duration`: Duración de la animación

**Efecto:**
```
Espera delay ms → Fade-in + slide-up
```

---

## 🎨 Tarjetas y Contenedores

### Card Estándar

```dart
Card(
  elevation: 4,
  margin: EdgeInsets.all(8),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Título'),
        SizedBox(height: 8),
        Text('Descripción'),
      ],
    ),
  ),
)
```

### Tarjeta con Imagen

```dart
Card(
  clipBehavior: Clip.antiAlias,
  child: Column(
    children: [
      Image.asset('assets/imagen.png'),
      Padding(
        padding: EdgeInsets.all(16),
        child: Text('Título'),
      ),
    ],
  ),
)
```

### Contenedor con Degradado

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
  ),
  padding: EdgeInsets.all(16),
  child: Text('Contenedor con Degradado'),
)
```

---

## 📝 Inputs y Formularios

### TextField Simple

```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Escribe aquí',
    labelText: 'Mi Campo',
    prefixIcon: Icon(Icons.person),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onChanged: (value) => print(value),
)
```

### Formulario Completo

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        decoration: InputDecoration(labelText: 'Email'),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Requerido';
          if (!value!.contains('@')) return 'Email inválido';
          return null;
        },
      ),
      SizedBox(height: 16),
      TextFormField(
        decoration: InputDecoration(labelText: 'Contraseña'),
        obscureText: true,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Requerido';
          if (value!.length < 6) return 'Mín 6 caracteres';
          return null;
        },
      ),
      SizedBox(height: 24),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Enviar formulario
          }
        },
        child: Text('Enviar'),
      ),
    ],
  ),
)
```

### DropdownButton

```dart
DropdownButton<String>(
  value: _selectedValue,
  items: [
    DropdownMenuItem(
      value: 'opcion1',
      child: Text('Opción 1'),
    ),
    DropdownMenuItem(
      value: 'opcion2',
      child: Text('Opción 2'),
    ),
  ],
  onChanged: (value) {
    setState(() => _selectedValue = value);
  },
)
```

---

## 📊 Barras de Progreso

### LinearProgressIndicator

```dart
LinearProgressIndicator(
  value: 0.75, // 0.0 a 1.0
  minHeight: 8,
  backgroundColor: Colors.grey[300],
  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
)
```

### CircularProgressIndicator

```dart
CircularProgressIndicator(
  value: 0.75,
  strokeWidth: 4,
  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
)
```

### Barra de Progreso Personalizada

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: LinearProgressIndicator(
    value: 0.75,
    minHeight: 12,
    backgroundColor: Colors.grey[300],
    valueColor: AlwaysStoppedAnimation<Color>(
      Color.lerp(Colors.red, Colors.green, 0.75),
    ),
  ),
)
```

---

## 🧭 Componentes de Navegación

### BottomNavigationBar

```dart
BottomNavigationBar(
  currentIndex: _currentIndex,
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Inicio',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: 'Cursos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_bag),
      label: 'Tienda',
    ),
  ],
  onTap: (index) {
    setState(() => _currentIndex = index);
  },
)
```

### AppBar Personalizado

```dart
AppBar(
  title: Text('KORULAB'),
  backgroundColor: Color(0xFF2E7D32),
  elevation: 4,
  actions: [
    IconButton(
      icon: Icon(Icons.notifications),
      onPressed: () => print('Notificaciones'),
    ),
    IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => print('Configuración'),
    ),
  ],
)
```

### Drawer (Menú Lateral)

```dart
Drawer(
  child: ListView(
    children: [
      DrawerHeader(
        decoration: BoxDecoration(color: Color(0xFF2E7D32)),
        child: Text(
          'KORULAB',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      ListTile(
        leading: Icon(Icons.home),
        title: Text('Inicio'),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: Icon(Icons.person),
        title: Text('Perfil'),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: Icon(Icons.logout),
        title: Text('Cerrar Sesión'),
        onTap: () => print('Logout'),
      ),
    ],
  ),
)
```

---

## ⭐ Componentes Especiales

### Badge

```dart
Badge(
  label: Text('3'),
  child: Icon(Icons.notifications),
)
```

### Chip

```dart
Chip(
  label: Text('Flutter'),
  onDeleted: () => print('Eliminar'),
  backgroundColor: Colors.blue[100],
)
```

### Tooltip

```dart
Tooltip(
  message: 'Este es un tooltip',
  child: Icon(Icons.info),
)
```

### Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('¿Estás seguro?'),
    content: Text('Esta acción no se puede deshacer.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancelar'),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          // Realizar acción
        },
        child: Text('Aceptar'),
      ),
    ],
  ),
)
```

### SnackBar

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Acción realizada exitosamente'),
    duration: Duration(seconds: 2),
    action: SnackBarAction(
      label: 'Deshacer',
      onPressed: () => print('Deshacer'),
    ),
  ),
)
```

---

## 💡 Ejemplos Prácticos

### 1. Tarjeta de Lección con Animación

```dart
AnimatedCard(
  delayDuration: Duration(milliseconds: 200),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset('assets/leccion.png', height: 200, fit: BoxFit.cover),
      ),
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lección 1: Conceptos Básicos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Aprende los fundamentos de la ecología'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progreso: 75%'),
                LinearProgressIndicator(value: 0.75, minWidth: 100),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
)
```

### 2. Formulario de Login con Animaciones

```dart
Column(
  children: [
    AnimatedItemEntry(
      delay: Duration(milliseconds: 200),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Usuario',
          prefixIcon: Icon(Icons.person),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    SizedBox(height: 16),
    AnimatedItemEntry(
      delay: Duration(milliseconds: 300),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Contraseña',
          prefixIcon: Icon(Icons.lock),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        obscureText: true,
      ),
    ),
    SizedBox(height: 24),
    AnimatedItemEntry(
      delay: Duration(milliseconds: 400),
      child: AnimatedElevatedButton(
        label: 'Iniciar Sesión',
        onPressed: () => print('Login'),
      ),
    ),
  ],
)
```

### 3. Lista de Cursos con Animación Escalonada

```dart
AnimatedListView(
  items: cursos.map((curso) {
    return AnimatedCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(curso.id.toString()),
        ),
        title: Text(curso.nombre),
        subtitle: Text('${curso.leccionesCompletadas}/${curso.totalLecciones} lecciones'),
        trailing: Icon(Icons.arrow_forward),
        onTap: () => print('Abrir ${curso.nombre}'),
      ),
    );
  }).toList(),
  itemDelay: Duration(milliseconds: 100),
)
```

### 4. Perfil de Usuario

```dart
Column(
  children: [
    Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            SizedBox(height: 16),
            Text(
              'Juan Pérez',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'juan@example.com',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estadísticas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(title: 'Puntos', value: '1,250'),
              _StatCard(title: 'Retos', value: '42'),
              _StatCard(title: 'Logros', value: '12'),
            ],
          ),
        ],
      ),
    ),
  ],
)
```

---

## 🎓 Mejores Prácticas

### 1. Reutilización de Widgets

```dart
// ❌ No hagas esto
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(...), // Widget completo
          Container(...), // Widget completo
        ],
      ),
    );
  }
}

// ✅ Haz esto
class MyCard extends StatelessWidget {
  final String title;
  const MyCard({required this.title});
  
  @override
  Widget build(BuildContext context) => Card(...);
}

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          MyCard(title: 'Card 1'),
          MyCard(title: 'Card 2'),
        ],
      ),
    );
  }
}
```

### 2. Usar const Constructors

```dart
// ✅ Mejor rendimiento
class MyWidget extends StatelessWidget {
  const MyWidget(); // const constructor
  
  @override
  Widget build(BuildContext context) {
    return const Text('Hello'); // const
  }
}
```

### 3. Organizar Widgets Grandes

```dart
class ComplexPage extends StatefulWidget {
  @override
  State<ComplexPage> createState() => _ComplexPageState();
}

class _ComplexPageState extends State<ComplexPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(title: Text('Mi Página'));
  }
  
  Widget _buildBody() {
    return ListView(...);
  }
  
  Widget _buildFAB() {
    return FloatingActionButton(...);
  }
}
```

---

**Última actualización:** 2026-11-11  
**Versión:** 1.0.0  
**Mantener:** Cuando agregues nuevos componentes
