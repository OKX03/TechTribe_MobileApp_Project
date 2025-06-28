import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memorime_v1/models/time_capsule.dart';

class CapsuleDetailPage extends StatelessWidget {
  final TimeCapsule capsule;

  const CapsuleDetailPage({super.key, required this.capsule});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          capsule.title,
          style: GoogleFonts.lato(color: Colors.black))
          ,
          backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0.5,
          ),

      
      body: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/default_profile_picture.jpg'),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(width: 8),
              Text(
                "Your Capsule",
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                ),
                const Spacer(),
                Icon(Icons.more_horiz),
            ],
          ),
          const SizedBox(height: 12),

          //Image display
          // Photo preview (with default fallback)
        ClipRRect(
          child: Image.network(
            capsule.photoUrls.isNotEmpty
                ? capsule.photoUrls.first
                : 'https://via.placeholder.com/400x250.png?text=No+Image', // 👈 default image URL
            fit: BoxFit.cover,
            height: 280,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 280,
                color: Colors.grey[300],
                child: const Center(child: Text("Failed to load image")),
              );
            },
          ),
        ),

          const SizedBox(height: 8),

          Row(
            children: [
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // Handle favorite action
                  print("Favorite tapped for capsule: ${capsule.title}");
                },
                child: Icon(
                  Icons.favorite_border_outlined, 
                  color: Colors.black, 
                  size: 24)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // Handle share action
                  print("Comment tapped for capsule: ${capsule.title}");
                },
                child: Icon(
                  Icons.chat_bubble_outline_outlined,
                  color: Colors.black, 
                  size: 24)),
            ],
          ),

          //Caption / Description
          Padding(
            padding: const EdgeInsets.only(left:8.0, top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: capsule.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: "  "), // spacing
                        TextSpan(
                          text: capsule.description,
                        ),
                      ],
                    ),
                  ),

              
                  Text(_formatDate(capsule.unlockDate),
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
              
                  Text(
                  "Created On: ${_formatDate(capsule.createdAt)}",
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.blueAccent,
                    fontStyle: FontStyle.italic
                  ),
                )
                ],
              ),
            ),
          ),

          

          const SizedBox(height: 6),

          
        ],
      ),
      
    );
  }
}

  String _formatDate(DateTime date) {
    return "${date.day} ${_monthName(date.month)} ${date.year}";
  }

  String _monthName(int month) {
    switch (month) {
      case 1: return "January";
      case 2: return "February";
      case 3: return "March";
      case 4: return "April";
      case 5: return "May";
      case 6: return "June";
      case 7: return "July";
      case 8: return "August";
      case 9: return "September";
      case 10: return "October";
      case 11: return "November";
      case 12: return "December";
      default: return "";
    }
  }

