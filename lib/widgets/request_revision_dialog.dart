import 'package:flutter/material.dart';

// Bu diyalog (dialog), Admin (Yönetici) "Revize İste" butonuna bastığında açılır.
// Bir 'StatefulWidget' (Durum Bilgili Bileşen) olmalı
// çünkü bir 'Form' (Form) ve 'TextEditingController' (Metin Düzenleme Denetleyicisi)
// içerecek.
class RequestRevisionDialog extends StatefulWidget {
  final String taskTitle;

  const RequestRevisionDialog({super.key, required this.taskTitle});

  @override
  State<RequestRevisionDialog> createState() => _RequestRevisionDialogState();
}

class _RequestRevisionDialogState extends State<RequestRevisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false; // "Gönder" butonu için

  // Bu fonksiyon, 'all_tasks_page.dart' (Tüm Görevler) sayfasına
  // geri dönecek ve o sayfa Firebase güncellemesini yapacak.
  // Bu diyalog (dialog) sadece notu girmek için var.
  void _submitRevisionNote() {
    // Formun geçerli olup olmadığını (notun boş olup olmadığını) kontrol et
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Yükleniyor durumunu başlat
      });

      // Diyaloğu (Dialog) kapat ve 'Navigator.pop' (Gezgin.kapat)
      // aracılığıyla girilen notu geri döndür.
      Navigator.of(context).pop(_noteController.text.trim());
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Revizyon Talebi: ${widget.taskTitle}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4, // Geniş bir diyalog (dialog)
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Revizyon Notu Metin Alanı
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Revizyon Notu',
                  hintText: 'Çalışanın neyi düzeltmesi gerektiğini buraya yazın...',
                  icon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 4, // 4 satırlık bir alan
                autofocus: true, // Diyalog (Dialog) açıldığında otomatik odaklan
                // Doğrulayıcı (Validator): Adminin (Yönetici)
                // bir not girmesi ZORUNLUDUR.
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir revizyon notu girin.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        // İptal Butonu
        TextButton(
          onPressed: _isLoading
              ? null
          // Diyaloğu (Dialog) kapat ve 'null' (boş) döndür
          // (işlemin iptal edildiğini belirtir)
              : () => Navigator.of(context).pop(null),
          child: const Text('İptal'),
        ),
        // Gönder Butonu
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRevisionNote,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent, // Buton kırmızı olsun
          ),
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Revize Talebi Gönder'),
        ),
      ],
    );
  }
}