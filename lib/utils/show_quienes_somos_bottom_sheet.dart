import 'package:flutter/material.dart';

const Color _primaryBlue = Color(0xFF0059B7);
const Color _primaryRed = Color(0xFFCC1F1F);
const Color _textDark = Color(0xFF1C1C1C);
const Color _textMuted = Color(0xFF5F6B7A);

void showQuienesSomosBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final altura = MediaQuery.sizeOf(ctx).height * 0.82;
      return SafeArea(
        child: SizedBox(
          height: altura,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDFE2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Título
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Quiénes Somos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Plásticos Duralon — Desde 1937',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Historia
                      const Text(
                        'En 1937, Julius Frankenberg, funda en Santo Domingo la '
                        'compañía J. Frankenberg, dedicada a la representación de '
                        'diversos renglones de importación.\n\n'
                        'En el 1960, su hijo Werner Frankenberg, da inicio a una nueva '
                        'etapa, incursionando en la manufactura, con una fábrica de '
                        'moldeo de plástico por inyección, para la fabricación de '
                        'cepillos dentales y peines, bajo la marca de Duralon, '
                        'evolucionando hasta convertirse en la marca líder de artículos '
                        'del hogar en la República Dominicana. En el año 1967, '
                        'incursiona en el área de soplado, para la fabricación de '
                        'botellas plásticas, lo que en 1988 se convierte en nuestra '
                        'división Novoplast.\n\n'
                        'Hoy, sirviendo a los diferentes ramos de las industrias y '
                        'público en general, nos enorgullecemos de haber mantenido '
                        'intactos los principios de nuestro fundador, esforzándonos '
                        'por llevar una solución a las necesidades de cada uno de '
                        'nuestros clientes, con la mejor calidad y un compromiso con '
                        'el servicio para lograr su total satisfacción.',
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Visión
                      _SectionTitle(
                        icon: Icons.visibility_outlined,
                        label: 'Visión',
                        color: _primaryBlue,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ser una empresa líder en la fabricación de plásticos '
                        'fundamentado en la calidad de nuestros productos en el '
                        'ámbito local con alcance internacional.',
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Misión
                      _SectionTitle(
                        icon: Icons.flag_outlined,
                        label: 'Misión',
                        color: _primaryRed,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sostener y promover un sistema óptimo de calidad basado en '
                        'la competitividad, calidad en el servicio, y la satisfacción '
                        'plena de las necesidades de nuestros clientes, manteniendo '
                        'la prosperidad y el desarrollo de nuestro negocio, nuestro '
                        'personal y medio ambiente.',
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              // Botón cerrar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
