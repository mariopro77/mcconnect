//foundation es necesaria para notificarle sobre cambios a los demas widgets 
import "package:flutter/foundation.dart";

class Visibilidadusuarios with ChangeNotifier{ 
  bool _mostrarUsuariosInactivos = false; //Variable privada para que no afecte la integridad

  //Getter publico para que otras variables puedan acceder a ella
  bool get mostrarUsuariosInactivos => _mostrarUsuariosInactivos;

  void toggleMostrarUsuariosInactivos () {
    _mostrarUsuariosInactivos = !_mostrarUsuariosInactivos;
    notifyListeners(); // Notifica a los widgets que están escuchando
  }
}