import 'package:Talab/data/model/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:Talab/data/cubits/category/fetch_category_cubit.dart';
import 'package:Talab/ui/theme/theme.dart';
import 'package:Talab/utils/ui_utils.dart';
import 'package:Talab/app/routes.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:Talab/ui/screens/home/widgets/category_home_card.dart';
import 'package:Talab/ui/screens/widgets/errors/no_data_found.dart';  

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:Talab/app/routes.dart';
import 'package:Talab/data/cubits/category/fetch_category_cubit.dart';
import 'package:Talab/ui/screens/home/home_screen.dart';
import 'package:Talab/ui/screens/home/widgets/category_home_card.dart';
import 'package:Talab/ui/screens/main_activity.dart';
import 'package:Talab/ui/screens/widgets/errors/no_data_found.dart';
import 'package:Talab/ui/theme/theme.dart';
import 'package:Talab/utils/app_icon.dart';
import 'package:Talab/utils/custom_text.dart';
import 'package:Talab/utils/extensions/extensions.dart';
import 'package:Talab/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';             //  UiUtils.getSvg(…)

/* ──────────────────────────────────────────────────────────────────────────
 * Switchable Category Widget for Home Screen
 *   - ViewMode.horizontal  … original ribbon (max 10 + “more”)
 *   - ViewMode.expanded    … accordion list with masonry sub-grid
 * Toggle between them with two icon buttons.
 * ──────────────────────────────────────────────────────────────────────────*/

enum _ViewMode { horizontal, expanded, staggered }

class CategoryWidgetHome extends StatefulWidget {
  const CategoryWidgetHome({super.key});

  @override
  State<CategoryWidgetHome> createState() => _CategoryWidgetHomeState();
}

class _CategoryWidgetHomeState extends State<CategoryWidgetHome> {
  _ViewMode _mode = _ViewMode.horizontal;
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
                : _StaggeredGridView(categories: state.categories);
          },
        ),
      ],
    );
  }

  /*───────────────────────────────────────────────────────────────────────────*/

  Widget _buildToggleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: sidePadding, right: sidePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Grid view',
            icon: Icon(Icons.grid_view_rounded,
                color: _mode == _ViewMode.expanded
                    ? context.color.territoryColor
                    : context.color.iconColor),
            onPressed: () => setState(() => _mode = _ViewMode.expanded),
          ),
          IconButton(
            tooltip: 'Staggered view',
            icon: Icon(Icons.view_agenda,
                color: _mode == _ViewMode.staggered
                    ? context.color.territoryColor
                    : context.color.iconColor),
            onPressed: () => setState(() => _mode = _ViewMode.staggered),
          ),
          IconButton(
            tooltip: 'Ribbon view',
            icon: Icon(Icons.view_stream,
                color: _mode == _ViewMode.horizontal
                    ? context.color.territoryColor
                    : context.color.iconColor),
            onPressed: () => setState(() => _mode = _ViewMode.horizontal),
          ),
        ],
      ),
    );
  }
}

extension on ColorScheme {
  get iconColor => null;
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

/* ────────────────────────  STAGGERED GRID VIEW  ──────────────────────────*/

class _StaggeredGridView extends StatelessWidget {
  final List<CategoryModel> categories;

  const _StaggeredGridView({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        itemCount: categories.length,
        itemBuilder: (BuildContext context, int index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              if (cat.children?.isNotEmpty ?? false) {
                Navigator.pushNamed(context, Routes.subCategoryScreen, arguments: {
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
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      cat.url!,
                      fit: BoxFit.cover,
                      height: index % 2 == 0 ? 150 : 200,
                      width: double.infinity,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      cat.name!,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
  }
}
