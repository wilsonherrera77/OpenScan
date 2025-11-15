import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Utilities/constants.dart';

void launchWebsite(String urlString) async {
  if (await canLaunch(urlString)) {
    await launch(urlString);
  } else {
    print("Couldn't launch the url");
  }
}

class AboutScreen extends StatelessWidget {
  static String route = "AboutScreen";
  final String vjLink = "https://www.linkedin.com/in/vijay-t-s/";
  final String vikramLink = "https://www.linkedin.com/in/vikram-harikrishnan/";

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          title: RichText(
            text: TextSpan(
              text: 'About',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.all(20),
          children: <Widget>[
            Center(
              child: Image.asset(
                'assets/scan_g.jpeg',
                scale: 6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  text: 'Lumara ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                        text: 'Scan', style: TextStyle(color: secondaryColor)),
                    TextSpan(
                      text:
                          ' es una aplicación inteligente para digitalizar, organizar y gestionar documentos de comunidades. Integrada con Paperless-ngx para archivo comunitario sin publicidad y con privacidad primero.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: size.height * 0.02,
            ),
            Center(
              child: Text(
                "Desarrollado para Comunidades",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              height: size.height * 0.02,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Sistema de digitalización documental diseñado específicamente para gestionar archivos comunitarios con privacidad, seguridad y accesibilidad.",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: size.height * 0.03,
            ),
            Center(
              child: Text(
                "Sin publicidad. No recopilamos datos.\nRespetamos tu privacidad.",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: size.height * 0.035,
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: secondaryColor.withOpacity(0.2),
                  border: Border.all(color: secondaryColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.integration_instructions, color: secondaryColor),
                    SizedBox(width: 10),
                    Text(
                      "Integrado con\nPaperless-ngx",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'Version ',
                style: TextStyle(fontSize: 14),
                children: [
                  TextSpan(
                      text: '4.5.1', style: TextStyle(color: secondaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final String link;
  final String name;
  final AssetImage image;

  const ContactCard({required this.link, required this.name, required this.image});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => launchWebsite(link),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        elevation: 10.0,
        child: Container(
          margin: EdgeInsets.all(8.0),
          height: size.width * 0.4,
          width: size.width * 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: secondaryColor,
                radius: size.width * 0.13,
                backgroundImage: image,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 0),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              // Text(
              //   'Tap for more',
              //   style: TextStyle(color: Colors.grey[700], fontSize: 12),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
