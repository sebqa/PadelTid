import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/document.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:js' as js;



class DocumentPage extends StatefulWidget {


  final Document document;

  DocumentPage({required this.document});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  bool following = false;
  final Uri _url = Uri.parse('https://holbaekpadel.dk/da/new/booking');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.date),
      ),
      body: Column(
        children: [
          Center(
            child: Text(widget.document.date),
          ),
          //add a text with hyperlink to google.com
          Center(
            child: Text(widget.document.symbolCode),
          ),
          Center(
            child: Text(widget.document.time),
          ),
          IconButton(
            icon: Icon(following ? Icons.star : Icons.star_border,color: Theme.of(context).colorScheme.primary,),
            onPressed: () {
              setState(() {
                following = !following;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: Duration(seconds: 1),
                  content: Text(
                    following ? 'Following timeslot' : 'No longer folloing timeslot',
                  ),
                ),
              );
            },
          ),
          ElevatedButton(
              onPressed: () => js.context.callMethod('open', [_url.toString()])
,
              child: Text('Go to court booking'),
            ),
        ],
      ),
    );
  }
  
}
