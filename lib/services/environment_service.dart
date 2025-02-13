import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Service responsible for managing environment configuration
class EnvironmentService {
  // Private constructor
  EnvironmentService._() {
    _initialize();
  }
  
  // Singleton instance
  static final EnvironmentService instance = EnvironmentService._();

  // API URLs
  static const String devBaseUrl = 'http://localhost:3000/api';
  static const String prodBaseUrl = 'https://order.bohurupi.com/api';
  
  // API Key
  static const String apiKey = 'x84kjjfkdjk';
  
  // Admin credentials
  static const String adminEmail = 'admin@bohurupi.com';
  static const String adminPassword = '33558822';

  // Authentication token cache
  String? _cachedAuthToken;

  void _initialize() {
    // Generate auth token at initialization
    _cachedAuthToken = _getBasicAuth();
    
    if (kDebugMode) {
      print('Environment Service Initialized');
      print('Development Mode: $isDevelopment');
      print('Base URL: $baseUrl');
    }
  }

  /// Determines if the app is running in development mode
  bool get isDevelopment {
    // For web platform
    if (kIsWeb) {
      // Check if running on localhost
      final host = Uri.base.host;
      return host == 'localhost' || host == '127.0.0.1';
    }
    
    // For mobile/desktop platforms
    // In release mode, always use production
    if (!kDebugMode) {
      return false;
    }
    
    // In debug mode, use development
    return true;
  }

  /// Gets the appropriate base URL based on environment
  String get baseUrl => isDevelopment ? devBaseUrl : prodBaseUrl;

  /// Gets the API headers with authentication
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
    'Authorization': 'Basic ${_cachedAuthToken ?? _getBasicAuth()}',
  };

  /// Gets the API headers without authentication
  Map<String, String> get headersWithoutAuth => {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
  };

  /// Generates Basic Auth string
  String _getBasicAuth() {
    if (_cachedAuthToken != null) return _cachedAuthToken!;
    
    final auth = '$adminEmail:$adminPassword';
    final bytes = utf8.encode(auth);
    _cachedAuthToken = base64.encode(bytes);
    
    if (kDebugMode) {
      print('Generated new auth token');
    }
    
    return _cachedAuthToken!;
  }

  /// Clears the cached auth token
  void clearAuthToken() {
    _cachedAuthToken = null;
  }
} 