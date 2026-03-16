import 'package:flutter/material.dart';
import 'f1_theme.dart';

class DriversTeamsSection extends StatelessWidget {
  final GlobalKey sectionKey;

  const DriversTeamsSection({super.key, required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    final drivers = <_DriverCardData>[
      const _DriverCardData("George Russell", "Mercedes", "assets/images/drivers/George_Russell.png"),
      const _DriverCardData("Kimi Antonelli", "Mercedes", "assets/images/drivers/Kimi_Antonelli.png"),
      const _DriverCardData("Charles Leclerc", "Ferrari", "assets/images/drivers/CL.png"),
      const _DriverCardData("Lewis Hamilton", "Ferrari", "assets/images/drivers/lewis_hamilton.png"),
      const _DriverCardData("Lando Norris", "McLaren", "assets/images/drivers/lando_norris.png"),
      const _DriverCardData("Max Verstappen", "Red Bull Racing", "assets/images/drivers/Max_Verstappen.png"),
      const _DriverCardData("Ollie Bearman", "Haas F1 Team", "assets/images/drivers/Ollie_Bearman.png"),
      const _DriverCardData("Arvid Lindblad", "Racing Bulls", "assets/images/drivers/Arvid_Lindblad.png"),
      const _DriverCardData("Gabriel Bortoleto", "Audi", "assets/images/drivers/Gabriel_Bortoleto.png"),
      const _DriverCardData("Pierre Gasly", "Alpine", "assets/images/drivers/Pierre_Gasly.png"),
      const _DriverCardData("Esteban Ocon", "Haas F1 Team", "assets/images/drivers/Esteban_Ocon.png"),
      const _DriverCardData("Alexander Albon", "Williams", "assets/images/drivers/Alexander_Albon.png"),
      const _DriverCardData("Liam Lawson", "Racing Bulls", "assets/images/drivers/Liam_Lawson.png"),
      const _DriverCardData("Franco Colapinto", "Alpine", "assets/images/drivers/Franco_Colapinto.png"),
      const _DriverCardData("Carlos Sainz", "Williams", "assets/images/drivers/Carlos_sainz.png"),
      const _DriverCardData("Sergio Perez", "Cadillac", "assets/images/drivers/Sergio_Perez.png"),
      const _DriverCardData("Lance Stroll", "Aston Martin", "assets/images/drivers/Lance_Stroll.png"),
      const _DriverCardData("Fernando Alonso", "Aston Martin", "assets/images/drivers/Fernando_Alonso.png"),
      const _DriverCardData("Valtteri Bottas", "Cadillac", "assets/images/drivers/Valtteri_Bottas.png"),
      const _DriverCardData("Isack Hadjar", "Red Bull Racing", "assets/images/drivers/Isack_Hadjar.png"),
      const _DriverCardData("Oscar Piastri", "McLaren", "assets/images/drivers/oscar_piastri.png"),
      const _DriverCardData("Nico Hulkenberg", "Audi", "assets/images/drivers/Nico_Hulkenberg.png"),
      const _DriverCardData("Jack Doohan", "Alpine", "assets/images/drivers/Jack_Doohan.png"),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        key: sectionKey,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32), // 🔥 rounded outer container
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Drivers",
              style: TextStyle(color: F1Theme.f1Red, fontSize: 72, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 30),

            LayoutBuilder(builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1000;

              final tileSize = isDesktop ? 320.0 : 240.0;
              const rows = 3;
              const spacing = 24.0;

              final height = (tileSize * rows) + (spacing * (rows - 1));

              return SizedBox(
                height: height,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _gridWidth(drivers.length, rows, tileSize, spacing),
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: drivers.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: rows,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (_, i) => _DriverCard(
                        data: drivers[i],
                        size: tileSize,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  double _gridWidth(int count, int rows, double size, double spacing) {
    final columns = (count / rows).ceil();
    return (columns * size) + ((columns - 1) * spacing);
  }
}

class _DriverCardData {
  final String name;
  final String team;
  final String image;

  const _DriverCardData(this.name, this.team, this.image);
}

class _DriverCard extends StatefulWidget {
  final _DriverCardData data;
  final double size;

  const _DriverCard({required this.data, required this.size});

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> {
  bool hovered = false;

  static const Alignment topBias = Alignment(0, -0.6); // 👈 keep face visible

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: hovered
            ? (Matrix4.identity()..translate(0.0, -6.0)..scale(1.03))
            : Matrix4.identity(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                widget.data.image,
                fit: BoxFit.cover,
                alignment: topBias,
              ),

              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: hovered ? 1 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: hovered ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.data.team,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}