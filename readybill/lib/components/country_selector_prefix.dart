import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:readybill/components/api_constants.dart';
import 'package:readybill/components/color_constants.dart';
import 'package:readybill/services/api_services.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

class Country {
  final String name;
  final String flagUrl;
  final String dialCode;
  final String code;

  const Country({
    required this.name,
    required this.flagUrl,
    required this.dialCode,
    required this.code,
  });

  static Country fromJson(Map<String, dynamic> json) {
    try {
      return Country(
        name: json['name'] ?? 'Unknown',
        flagUrl: json['flag'] ?? '',
        dialCode: json['dial_code'] ?? '',
        code: json['code'] ?? '',
      );
    } catch (e) {
      print('Error parsing country data: $e');
      return const Country(
        name: 'Unknown',
        flagUrl: '',
        dialCode: '',
        code: 'XX',
      );
    }
  }
}

class CountrySelectorPrefix extends StatefulWidget {
  final String? initialCountryCode;
  final double? width;
  final TextStyle? textStyle;
  final Function provider;

  const CountrySelectorPrefix({
    super.key,
    this.width,
    this.textStyle,
    required this.provider,
    this.initialCountryCode,
  });

  @override
  State<CountrySelectorPrefix> createState() => _CountrySelectorPrefixState();
}

class _CountrySelectorPrefixState extends State<CountrySelectorPrefix> {
  List<Map<String, dynamic>>? _countriesData;
  bool _isLoadingCountries = true;
  bool _isDetectingCountry = true;
  String? _error;
  Country? _selectedCountry;
  String _searchQuery = '';
  late List<Country> _countries = [];

  @override
  void initState() {
    super.initState();
    _loadCountriesAndInitialize();
  }

  Future<void> _loadCountriesAndInitialize() async {
    await _loadCountries();
    await _initializeDeviceCountry();
  }

  Future<void> _loadCountries() async {
    try {
      var apiKey = await APIService.getXApiKey();
      var token = await APIService.getToken();

      var response = await http.get(
        Uri.parse('$baseUrl/countries-json'),
        headers: {
          'token': '$token',
          'auth-key': '$apiKey',
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        List<dynamic> data =
            jsonResponse is List ? jsonResponse : [jsonResponse];

        setState(() {
          _countriesData = data.whereType<Map<String, dynamic>>().toList();
          _initializeCountries();
          _isLoadingCountries = false;
        });
      } else {
        print("Failed to load countries: ${response.body}");
        throw Exception('Failed to load countries: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingCountries = false;
        _isDetectingCountry = false;
        _error = e.toString();
      });
      print('Error loading countries: $e');
    }
  }

  Future<void> _initializeDeviceCountry() async {
    if (widget.initialCountryCode != null && widget.initialCountryCode != '') {
      if (_countriesData != null) {
        try {
          final countryData = _countriesData!.firstWhere(
            (country) =>
                country['dial_code'].toString().replaceAll('+', '') ==
                widget.initialCountryCode!.toString(),
            orElse: () => _countriesData!.first,
          );

          setState(() {
            _selectedCountry = Country.fromJson(countryData);
            _isDetectingCountry = false;
          });
        } catch (e) {
          print('Error finding country by dial code: $e');
          setState(() {
            _isDetectingCountry = false;
          });
        }
      } else {
        setState(() {
          _isDetectingCountry = false;
        });
      }
      return;
    }

    try {
      // final String currentCountryCode = await getCountryName();
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? currentCountryCode = prefs.getString('countryCode');

      if (_countriesData != null) {
        try {
          final countryData = _countriesData!.firstWhere(
            (country) =>
                country['code']?.toString().toUpperCase() == currentCountryCode,
            orElse: () => _countriesData!.first,
          );

          setState(() {
            _selectedCountry = Country.fromJson(countryData);
            _isDetectingCountry = false;
          });
        } catch (e) {
          print('Error finding country by code: $e');
          if (_countries.isNotEmpty) {
            setState(() {
              _selectedCountry = _countries.first;
              _isDetectingCountry = false;
            });
          }
        }
      } else {
        setState(() {
          _isDetectingCountry = false;
        });
      }
    } catch (e) {
      print('Error getting device country: $e');
      if (_countries.isNotEmpty) {
        setState(() {
          _selectedCountry = _countries.first;
          _isDetectingCountry = false;
        });
      } else {
        setState(() {
          _isDetectingCountry = false;
        });
      }
    }
  }

  void _initializeCountries() {
    try {
      _countries = _countriesData!
          .map((json) {
            try {
              return Country.fromJson(json);
            } catch (e) {
              print("Error parsing country: $json -> $e");
              return null;
            }
          })
          .where((country) =>
              country != null &&
              country.name.isNotEmpty &&
              country.code.isNotEmpty)
          .cast<Country>()
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      print('Error initializing countries: $e');
      _countries = [];
    }
  }

  List<Country> get _filteredCountries {
    if (_searchQuery.isEmpty) return _countries;
    return _countries.where((country) {
      return country.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          country.dialCode.contains(_searchQuery) ||
          country.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _showCountryPicker() async {
    if (_countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
          'No countries available',
          style: TextStyle(
            fontFamily: 'Roboto-Regular',
          ),
        )),
      );
      return;
    }

    final result = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return _buildCountryPickerSheet();
      },
    );

    if (result != null) {
      setState(() => _selectedCountry = result);
    }
  }

  Widget _buildCountryPickerSheet() {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  _buildPickerHeader(context),
                  _buildSearchField(setState),
                  const Divider(),
                  _buildCountryList(scrollController),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPickerHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Select Country',
              style: TextStyle(
                fontFamily: 'Roboto-Regular',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search country, code or dial code',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildCountryList(ScrollController scrollController) {
    if (_selectedCountry == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: _filteredCountries.length,
        itemBuilder: (context, index) {
          final country = _filteredCountries[index];
          return ListTile(
            leading: Text(
              country.flagUrl,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Roboto-Regular',
              ),
            ),
            title: Text(country.name),
            trailing: Text(
              country.dialCode,
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'Roboto-Regular',
              ),
            ),
            selected: _selectedCountry != null &&
                country.code == _selectedCountry!.code,
            onTap: () {
              setState(() {
                print("countru code${country.code}");
                widget.provider(country.code);
              });
              Navigator.pop(context, country);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final width = widget.width ?? 90.0;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // A smaller, more elegant loading indicator
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Placeholder text that maintains layout similar to when country is shown
          Text(
            '...',
            style: widget.textStyle ??
                TextStyle(
                  color: Theme.of(context).hintColor,
                  fontFamily: 'Roboto-Regular',
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCountries || _isDetectingCountry) {
      return _buildLoadingIndicator();
    }

    if (_error != null) {
      return Container(
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: red, size: 16),
            SizedBox(width: 4),
            Text(
              'Error',
              style: TextStyle(fontFamily: 'Roboto-Regular', color: red),
            ),
          ],
        ),
      );
    }

    if (_selectedCountry == null) {
      return _buildLoadingIndicator();
    }

    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCountry!.flagUrl,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 4),
            Text(
              _selectedCountry!.dialCode,
              style: widget.textStyle,
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
