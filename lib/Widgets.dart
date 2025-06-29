import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Search.dart';
import 'my_flutter_app_icons.dart';

class CircleTabIndicator extends Decoration {
  final BoxPainter _painter;

  CircleTabIndicator({required Color color, required double radius})
      : _painter = _CirclePainter(color, radius);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _painter;
}

class _CirclePainter extends BoxPainter {
  final Paint _paint;
  final double radius;

  _CirclePainter(Color color, this.radius)
      : _paint = Paint()
    ..color = color
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size;
    if (size == null) return;
    final circleOffset = offset + Offset(size.width / 2, size.height - radius);
    canvas.drawCircle(circleOffset, radius, _paint);
  }
}

class About extends StatelessWidget {
  const About({super.key});

  Future<void> _sendFeedback(BuildContext context) async {
    final email = Email(
      body: '',
      subject: 'Poster Feedback',
      recipients: ['mechocreations@gmail.com'],
      isHTML: false,
    );
    try {
      await FlutterEmailSender.send(email);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send feedback: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        children: [
          Center(
            child: Text(
              'Poster',
              style: TextStyle(
                fontSize: 40,
                color: Theme.of(context).colorScheme.secondary,
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Poster is a free app offering beautiful, high-resolution wallpapers.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(
            'Poster provides daily uploads of high-quality wallpapers.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(
            'Poster supports both dark and light themes.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Divider(color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.asset(
                    'assets/author1.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: 60,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    'Developed by',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'Kamesh Vadivel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '@Mecho Creations',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.secondary,
                      fontFamily: 'SF-Pro-Text',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  MyFlutterApp.instagram,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                ),
                onPressed: () => _launchUrl('https://www.instagram.com/mecho_creations/'),
              ),
              IconButton(
                icon: Icon(
                  MyFlutterApp.twitter,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                ),
                onPressed: () => _launchUrl('https://twitter.com/CreationsMecho'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'Please share your feedback!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          Center(
            child: IconButton(
              icon: Icon(
                MyFlutterApp.email,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () => _sendFeedback(context),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String subTitle;
  final double barHeight;
  final bool isVisible;
  final TabController? tabController;

  const GradientAppBar(
      this.title,
      this.barHeight,
      this.subTitle,
      this.isVisible, {
        this.tabController,
        super.key,
      });

  @override
  State<GradientAppBar> createState() => _GradientAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(barHeight);
}

class _GradientAppBarState extends State<GradientAppBar> {
  List<DocumentSnapshot>? _carouselList;
  late final StreamSubscription<QuerySnapshot> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseFirestore.instance
        .collection('Carousel')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _carouselList = snapshot.docs;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Latest', 'Hot', 'Trending', 'Collections', 'Favorites'];

    if (widget.title == 'Poster') {
      return Container(
        height: widget.barHeight,
        width: MediaQuery.of(context).size.width,
        color: Theme.of(context).colorScheme.surface,
        child: widget.isVisible && _carouselList != null
            ? Stack(
          fit: StackFit.expand,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: widget.barHeight,
                enableInfiniteScroll: true,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 1.0,
                autoPlayCurve: Curves.easeIn,
                autoPlayInterval: const Duration(seconds: 2),
                autoPlayAnimationDuration: const Duration(milliseconds: 500),
                scrollDirection: Axis.horizontal,
              ),
              items: _carouselList!.map((doc) {
                final url = doc.get('url') as String?;
                return CachedNetworkImage(
                  imageUrl: url ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[300]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              }).toList(),
            ),
            Container(
              height: widget.barHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          MyFlutterApp.format_align_left,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 30,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening drawer')),
                          );
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SearchPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 46,
                          fontFamily: 'SF-Pro-Text',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                        child: Text(
                          widget.subTitle,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontFamily: 'SF-Pro-Text',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.tabController != null)
                  TabBar(
                    controller: widget.tabController,
                    tabs: titles
                        .map((title) => Tab(
                      text: title,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontFamily: 'SF-Pro-Text',
                        ),
                      ),
                    ))
                        .toList(),
                    indicator: CircleTabIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                      radius: 4,
                    ),
                    isScrollable: true,
                    labelPadding: const EdgeInsets.all(9.5),
                  ),
              ],
            ),
          ],
        )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: widget.barHeight,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 46,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                  child: Text(
                    widget.subTitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontFamily: 'SF-Pro-Text',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}