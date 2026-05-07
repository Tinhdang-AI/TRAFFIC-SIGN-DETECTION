// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class RegisterPage extends StatefulWidget {
//   const RegisterPage({super.key});

//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   final Color primaryGreen = const Color(0xFF054B1E);
//   final Color bgColor = const Color(0xFFF3F7F4);
//   final Color inputBgColor = const Color(0xFFE5EAE6);
//   final Color textGrey = const Color(0xFF7A8B80);
//   final Color textDark = const Color(0xFF2A362E);

//   bool _obscureText = true;
//   bool _obscureConfirmText = true;
//   bool _agreedToTerms = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, color: textDark),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.shield, color: primaryGreen, size: 24),
//             const SizedBox(width: 8),
//             Text(
//               'GUARDIAN',
//               style: GoogleFonts.montserrat(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w900,
//                 color: primaryGreen,
//                 letterSpacing: 1.2,
//               ),
//             ),
//           ],
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 10),
//               // Title
//               Text(
//                 'Create Account',
//                 style: GoogleFonts.inter(
//                   fontSize: 32,
//                   fontWeight: FontWeight.w900,
//                   color: textDark,
//                   letterSpacing: -0.5,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Start your journey with Signal Clarity.',
//                 style: GoogleFonts.inter(
//                   fontSize: 16,
//                   color: textGrey,
//                 ),
//               ),
//               const SizedBox(height: 32),
              
//               // Full Name
//               _buildInputLabel('FULL NAME'),
//               const SizedBox(height: 8),
//               _buildTextField(
//                 hintText: 'John Doe',
//                 icon: Icons.person_outline,
//               ),
//               const SizedBox(height: 20),
              
//               // Email
//               _buildInputLabel('EMAIL ADDRESS'),
//               const SizedBox(height: 8),
//               _buildTextField(
//                 hintText: 'name@example.com',
//                 icon: Icons.mail_outline,
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 20),
              
//               // Password
//               _buildInputLabel('PASSWORD'),
//               const SizedBox(height: 8),
//               _buildPasswordField(
//                 hintText: '••••••••',
//                 icon: Icons.lock_outline,
//                 obscureText: _obscureText,
//                 onToggle: () {
//                   setState(() {
//                     _obscureText = !_obscureText;
//                   });
//                 },
//               ),
//               const SizedBox(height: 20),
              
//               // Confirm Password
//               _buildInputLabel('CONFIRM PASSWORD'),
//               const SizedBox(height: 8),
//               _buildPasswordField(
//                 hintText: '••••••••',
//                 icon: Icons.verified_user_outlined,
//                 obscureText: _obscureConfirmText,
//                 onToggle: () {
//                   setState(() {
//                     _obscureConfirmText = !_obscureConfirmText;
//                   });
//                 },
//               ),
//               const SizedBox(height: 24),
              
//               // Terms and Conditions
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: Checkbox(
//                       value: _agreedToTerms,
//                       onChanged: (value) {
//                         setState(() {
//                           _agreedToTerms = value ?? false;
//                         });
//                       },
//                       activeColor: primaryGreen,
//                       side: BorderSide(color: textGrey.withOpacity(0.5), width: 1.5),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: RichText(
//                       text: TextSpan(
//                         style: GoogleFonts.inter(color: textDark, fontSize: 13, height: 1.4),
//                         children: [
//                           const TextSpan(text: 'I agree to the '),
//                           TextSpan(
//                             text: 'Terms and Conditions',
//                             style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
//                           ),
//                           const TextSpan(text: ' and '),
//                           TextSpan(
//                             text: 'Privacy Policy',
//                             style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 32),
              
//               // Register Button
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
//                       'Register',
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
              
//               // Login text
//               Wrap(
//                 alignment: WrapAlignment.center,
//                 children: [
//                   Text(
//                     "Already have an account? ",
//                     style: GoogleFonts.inter(
//                       color: textGrey,
//                       fontSize: 14,
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.pop(context);
//                     },
//                     child: Text(
//                       "Secure Login",
//                       style: GoogleFonts.inter(
//                         color: primaryGreen,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInputLabel(String label) {
//     return Text(
//       label,
//       style: GoogleFonts.inter(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: textGrey,
//         letterSpacing: 1.0,
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required String hintText,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: inputBgColor,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TextField(
//         keyboardType: keyboardType,
//         style: GoogleFonts.inter(color: textDark),
//         decoration: InputDecoration(
//           hintText: hintText,
//           hintStyle: GoogleFonts.inter(color: textGrey.withOpacity(0.6)),
//           prefixIcon: Icon(icon, color: textGrey),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         ),
//       ),
//     );
//   }

//   Widget _buildPasswordField({
//     required String hintText,
//     required IconData icon,
//     required bool obscureText,
//     required VoidCallback onToggle,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: inputBgColor,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TextField(
//         obscureText: obscureText,
//         style: GoogleFonts.inter(color: textDark),
//         decoration: InputDecoration(
//           hintText: hintText,
//           hintStyle: GoogleFonts.inter(color: textGrey.withOpacity(0.6)),
//           prefixIcon: Icon(icon, color: textGrey),
//           suffixIcon: IconButton(
//             icon: Icon(
//               obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
//               color: textGrey,
//             ),
//             onPressed: onToggle,
//           ),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         ),
//       ),
//     );
//   }
// }
