// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:Talab/app/routes.dart';
import 'package:Talab/data/cubits/category/fetch_category_cubit.dart';
import 'package:Talab/data/model/category_model.dart';
import 'package:Talab/ui/screens/home/home_screen.dart';
import 'package:Talab/ui/screens/home/widgets/category_home_card.dart';
import 'package:Talab/ui/screens/main_activity.dart';
import 'package:Talab/ui/screens/widgets/errors/no_data_found.dart';
import 'package:Talab/ui/theme/theme.dart';
import 'package:Talab/utils/app_icon.dart';
import 'package:Talab/utils/custom_text.dart';
import 'package:Talab/utils/extensions/extensions.dart';
import 'package:Talab/utils/ui_utils.dart';

/* ──────────────────────────────────────────────────────────────────────────
 * Switchable Category Widget for Home Screen
 *   - ViewMode.horizontal  … original ribbon (max 10 + “more”)
 *   - ViewMode.expanded    … accordion list with masonry sub-grid
 *   - ViewMode.staggered   … flat staggered grid of top-level categories
 * Toggle between them with three icon buttons.
 * ──────────────────────────────────────────────────────────────────────────*/

enum _ViewMode { horizontal, expanded, staggered }

class CategoryWidgetHome extends StatefulWidget {
  const CategoryWidgetHome({super.key});

  @override
  State<CategoryWidgetHome> createState() => _CategoryWidgetHomeState();
}

class _CategoryWidgetHomeState extends State<CategoryWidgetHome> {
 _ViewMode _mode = _ViewMode.staggered;
  final Map<int, bool> _expanded = {}; // remembers which parent cats are open

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToggleBar(context),
        BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
          builder: (context, state) {
            if (state is! FetchCategorySuccess) return const SizedBox.shrink();
            if (state.categories.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(50),
                child: NoDataFound(),
              );
            }

            return _mode == _ViewMode.horizontal
                ? _HorizontalRibbon(
                    categories: state.categories,
                    onMoreTapped: () => Navigator.pushNamed(
                      context,
                      Routes.categories,
                      arguments: {"from": Routes.home},
                    ),
                  )
                : _mode == _ViewMode.expanded
                    ? _AccordionGrid(
                        categories: state.categories,
                        expanded: _expanded,
                        onToggle: (id) => setState(() {
                          _expanded[id] = !(_expanded[id] ?? false);
                        }),
                      )
                    : _StaggeredGridView(
                        categories: state.categories,
                      );
          },
        ),
      ],
    );
  }

  // /───────────────────────────────────────────────────────────────────────────/

  Widget _buildToggleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: sidePadding, right: sidePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Ribbon view',
            icon: Icon(Icons.view_stream,
                color: _mode == _ViewMode.horizontal
                    ? context.color.territoryColor
                    : context.color.iconColor),
            onPressed: () => setState(() => _mode = _ViewMode.horizontal),
          ),
          IconButton(
            tooltip: 'Grid view',
            icon: Icon(Icons.grid_view_rounded,
                color: _mode == _ViewMode.expanded
                    ? context.color.territoryColor
                    : context.color.iconColor),
            onPressed: () => setState(() => _mode = _ViewMode.expanded),
          ),
          IconButton(
            tooltip: 'Staggered grid view',
            icon: Icon(Icons.view_module_rounded,
                color: _mode == _ViewMode.staggered
                    ? context.color.territoryColor
                    : context.color.iconColor),
            onPressed: () => setState(() => _mode = _ViewMode.staggered),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────  HORIZONTAL  ──────────────────────────────────*/

class _HorizontalRibbon extends StatelessWidget {
  const _HorizontalRibbon({
    required this.categories,
    required this.onMoreTapped,
  });

  final List<CategoryModel> categories; // adjust to your model import
  final VoidCallback onMoreTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: context.screenWidth,
        height: 103,
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            if (categories.length > 10 && index == categories.length) {
              return _MoreCard(onTap: onMoreTapped);
            }
            final cat = categories[index];
            return CategoryHomeCard(
              title: cat.name!,
              url: cat.url!,
              onTap: () {
                if (cat.children?.isNotEmpty ?? false) {
                  Navigator.pushNamed(context, Routes.subCategoryScreen,
                      arguments: {
                        'categoryList': cat.children,
                        'catName': cat.name,
                        'catId': cat.id,
                        'categoryIds': [cat.id.toString()]
                      });
                } else {
                  Navigator.pushNamed(context, Routes.itemsList, arguments: {
                    'catID': cat.id.toString(),
                    'catName': cat.name,
                    'categoryIds': [cat.id.toString()]
                  });
                }
              },
            );
          },
          itemCount: categories.length > 10
              ? categories.length + 1
              : categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
        ),
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                height: 70,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: context.color.borderColor.darken(60), width: 1),
                    color: context.color.secondaryColor),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: UiUtils.getSvg(AppIcons.more,
                        color: context.color.territoryColor),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CustomText(
                    'more'.translate(context),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    color: context.color.textDefaultColor,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/* ────────────────────────  EXPANDABLE GRID  ──────────────────────────────*/

class _AccordionGrid extends StatelessWidget {
  const _AccordionGrid({
    required this.categories,
    required this.expanded,
    required this.onToggle,
  });

  final List<CategoryModel> categories;
  final Map<int, bool> expanded;
  final void Function(int id) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: sidePadding),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: categories.length,
        itemBuilder: (_, idx) {
          final cat = categories[idx];
          final isOpen = expanded[cat.id!] ?? false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => onToggle(cat.id!),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat.name!,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Icon(
                          isOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.blue.shade900),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: !isOpen
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MasonryGridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2),
                          itemCount: cat.children?.length ?? 0,
                          itemBuilder: (_, subIdx) {
                            final subCat = cat.children![subIdx];
                            return GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                Routes.itemsList,
                                arguments: {
                                  'catID': subCat.id.toString(),
                                  'catName': subCat.name,
                                  'categoryIds': [subCat.id.toString()]
                                },
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 3))
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      Image.network(subCat.url!,
                                          fit: BoxFit.cover,
                                          height: 120,
                                          width: double.infinity,
                                          loadingBuilder:
                                              (context, child, progress) =>
                                                  progress == null
                                                      ? child
                                                      : const Center(
                                                          child:
                                                              CircularProgressIndicator())),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          color:
                                              Colors.black.withOpacity(0.6),
                                          child: Text(subCat.name!,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/* ────────────────────────  STAGGERED GRID  ──────────────────────────────*/
class _StaggeredGridView extends StatelessWidget {
  const _StaggeredGridView({
    required this.categories,
  });

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: StaggeredGrid.count(
        crossAxisCount: 10, // Total grid width
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        children: List.generate(categories.length, (index) {
          final cat = categories[index];

         
         // New pattern: a, b, b, a, a, b, b, a → based on index % 4
final crossAxisCellCount = (index % 4 == 0 || index % 4 == 3) ? 7 : 3;

          // Alternating background colors
          final List<Color> backgroundColors = [
            Color(0xFFD4EDFE), // rgb(215, 241, 185)// rgb(218, 226, 240), // #F2F2F2, // #FEE9D9,// #D4EDFE// #DAE2F0 // Odd tiles
            Color(0xFFFFE5F0), // Even tiles
          ];
         final Color tileColor = backgroundColors[(index % 4 == 0 || index % 4 == 3) ? 0 : 1];
            //////////ALTERING POSITION 
         final double leftOffset = (index % 4 == 0 || index % 4 == 3) ? 0.53 : 0.2;
final double topOffset = (index % 4 == 0 || index % 4 == 3) ? 0.40 : 0.3;
            ////////////ALTERING SIZE 
final double widthFactor = (index % 4 == 0 || index % 4 == 3) ? 0.5 : 1.0;
final double heightFactor = (index % 4 == 0 || index % 4 == 3) ? 0.6 : 0.8;

          return StaggeredGridTile.count(
            crossAxisCellCount: crossAxisCellCount,
            mainAxisCellCount: 4, // Consistent height
            child: GestureDetector(
              onTap: () {
                if (cat.children?.isNotEmpty ?? false) {
                  Navigator.pushNamed(context, Routes.subCategoryScreen,
                      arguments: {
                        'categoryList': cat.children,
                        'catName': cat.name,
                        'catId': cat.id,
                        'categoryIds': [cat.id.toString()]
                      });
                } else {
                  Navigator.pushNamed(context, Routes.itemsList, arguments: {
                    'catID': cat.id.toString(),
                    'catName': cat.name,
                    'categoryIds': [cat.id.toString()]
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned(
                          left: constraints.maxWidth * leftOffset,
                          top: constraints.maxHeight * topOffset,
                          child: Container(
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SizedBox(
                              width: constraints.maxWidth * widthFactor,
                              height: constraints.maxHeight * heightFactor,
                              child: Image.network(
                                cat.url!,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(child: CircularProgressIndicator()),
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.red.withOpacity(0.1),
                                    child: const Center(
                                      child: Text(
                                        'Image not found',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      Positioned(
  top: 5,
  left: 1,
  right: 1,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Text(
      cat.name!.toUpperCase(),
      textAlign: TextAlign.left,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: (index % 4 == 0 || index % 4 == 3)
            ? const Color.fromARGB(255, 0, 0, 0)
            : Colors.black, // Pattern-based color
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
      ),
    ),
  ),
),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

extension on ColorScheme {
  get iconColor => null;
}
