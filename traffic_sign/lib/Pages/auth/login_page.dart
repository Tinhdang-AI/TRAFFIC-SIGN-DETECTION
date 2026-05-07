// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'register_page.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final Color primaryGreen = const Color(0xFF054B1E);
//   final Color bgColor = const Color(0xFFF3F7F4);
//   final Color inputBgColor = const Color(0xFFE5EAE6);
//   final Color textGrey = const Color(0xFF7A8B80);
//   final Color textDark = const Color(0xFF2A362E);

//   bool _obscureText = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 20),
//               // Logo
//               Center(
//                 child: Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: primaryGreen,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: primaryGreen.withOpacity(0.3),
//                         blurRadius: 15,
//                         offset: const Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   child: const Icon(Icons.shield, color: Colors.white, size: 30),
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // App Name
//               Center(
//                 child: Text(
//                   'GUARDIAN',
//                   style: GoogleFonts.montserrat(
//                     fontSize: 28,
//                     fontWeight: FontWeight.w900,
//                     color: primaryGreen,
//                     letterSpacing: 1.5,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Welcome Text
//               Center(
//                 child: Text(
//                   'Welcome back to\nClarity',
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.inter(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: textDark,
//                     height: 1.2,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Center(
//                 child: Text(
//                   'Sign in to resume your safe driving\nexperience',
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.inter(
//                     fontSize: 14,
//                     color: textGrey,
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
              
//               // Email
//               Text(
//                 'EMAIL ADDRESS',
//                 style: GoogleFonts.inter(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: textGrey,
//                   letterSpacing: 1.0,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 decoration: BoxDecoration(
//                   color: inputBgColor,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: TextField(
//                   keyboardType: TextInputType.emailAddress,
//                   style: GoogleFonts.inter(color: textDark),
//                   decoration: InputDecoration(
//                     hintText: 'driver@guardian.app',
//                     hintStyle: GoogleFonts.inter(color: textGrey.withOpacity(0.6)),
//                     prefixIcon: Icon(Icons.mail_outline, color: textGrey),
//                     border: InputBorder.none,
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
              
//               // Password
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'PASSWORD',
//                     style: GoogleFonts.inter(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: textGrey,
//                       letterSpacing: 1.0,
//                     ),
//                   ),
//                   Text(
//                     'Forgot Password?',
//                     style: GoogleFonts.inter(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: primaryGreen,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 decoration: BoxDecoration(
//                   color: inputBgColor,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: TextField(
//                   obscureText: _obscureText,
//                   style: GoogleFonts.inter(color: textDark),
//                   decoration: InputDecoration(
//                     hintText: '••••••••',
//                     hintStyle: GoogleFonts.inter(color: textGrey.withOpacity(0.6)),
//                     prefixIcon: Icon(Icons.lock_outline, color: textGrey),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
//                         color: textGrey,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscureText = !_obscureText;
//                         });
//                       },
//                     ),
//                     border: InputBorder.none,
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),
              
//               // Login Button
//               ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryGreen,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 5,
//                   shadowColor: primaryGreen.withOpacity(0.4),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       'Login',
//                       style: GoogleFonts.inter(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     const Icon(Icons.arrow_forward, size: 20),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 32),
              
//               // Or Connect With
//               Row(
//                 children: [
//                   Expanded(child: Divider(color: inputBgColor, thickness: 1.5)),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Text(
//                       'OR CONNECT WITH',
//                       style: GoogleFonts.inter(
//                         fontSize: 11,
//                         color: textGrey,
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: 1.0,
//                       ),
//                     ),
//                   ),
//                   Expanded(child: Divider(color: inputBgColor, thickness: 1.5)),
//                 ],
//               ),
//               const SizedBox(height: 24),
              
//               // Social Buttons
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () {},
//                       icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png', width: 18),
//                       label: Text(
//                         'Google',
//                         style: GoogleFonts.inter(
//                           color: textDark,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         side: BorderSide(color: inputBgColor, width: 1.5),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () {},
//                       icon: const Icon(Icons.apple, color: Colors.black, size: 22),
//                       label: Text(
//                         'Apple',
//                         style: GoogleFonts.inter(
//                           color: textDark,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         side: BorderSide(color: inputBgColor, width: 1.5),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 32),
              
//               // Register text
//               Wrap(
//                 alignment: WrapAlignment.center,
//                 children: [
//                   Text(
//                     "Don't have an account yet? ",
//                     style: GoogleFonts.inter(
//                       color: textGrey,
//                       fontSize: 14,
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
//                     },
//                     child: Text(
//                       "Register Now",
//                       style: GoogleFonts.inter(
//                         color: primaryGreen,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: 40),
//               // Bottom Icons Watermark
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.traffic, color: textGrey.withOpacity(0.3), size: 30),
//                   const SizedBox(width: 24),
//                   Icon(Icons.directions_car, color: textGrey.withOpacity(0.3), size: 30),
//                   const SizedBox(width: 24),
//                   Icon(Icons.speed, color: textGrey.withOpacity(0.3), size: 30),
//                 ],
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
