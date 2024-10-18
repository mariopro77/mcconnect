import "package:flutter/material.dart";

class ContenidoDrawer extends StatelessWidget {
  const ContenidoDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  Image.asset(
                    "Icons/UserIcon.png", // Ensure this is referenced in pubspec.yaml
                    height: 100,
                    width: 100,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text("Hola Wander!",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Opciones",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  foregroundColor: const Color(0xFF17A2B8),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 30, color: Colors.black87),
                      Padding(
                        padding: EdgeInsets.only(left: 6, top: 4),
                        child: Text('Empleados',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
