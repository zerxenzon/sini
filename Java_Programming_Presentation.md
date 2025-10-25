---
marp: true
theme: default
paginate: true
---

# Java Programming
## Panduan Lengkap untuk Pemula

---

## 1. History of Java

### Sejarah Java
- **1991**: Dimulai oleh James Gosling di Sun Microsystems
- **1995**: Java 1.0 dirilis secara resmi
- **2010**: Oracle mengakuisisi Sun Microsystems
- **Sekarang**: Java versi 21+ (LTS)

### Filosofi Java
- **WORA**: Write Once, Run Anywhere
- Platform independent
- Object-oriented
- Secure dan robust

---

## 2. IDE (Integrated Development Environment)

### Popular Java IDEs

1. **IntelliJ IDEA** ⭐
   - Professional dan Community Edition
   - Smart code completion

2. **Eclipse**
   - Open source dan gratis
   - Banyak plugin tersedia

3. **NetBeans**
   - Mudah untuk pemula
   - Built-in support untuk Java

4. **Visual Studio Code**
   - Lightweight dengan extensions

---

## 3. Sintaks (Rule Java)

### Aturan Dasar Java

```java
// Struktur dasar program Java
public class NamaClass {
    public static void main(String[] args) {
        // Kode program di sini
        System.out.println("Hello, World!");
    }
}
```

### Rules Penting:
- ✅ Case-sensitive
- ✅ Setiap statement diakhiri dengan `;`
- ✅ Nama class harus sama dengan nama file
- ✅ main() method sebagai entry point
- ✅ Gunakan `{ }` untuk block code

---

## 4. Variable & Type Data

### Deklarasi Variable

```java
// Sintaks: tipeData namaVariable = nilai;
int umur = 25;
double harga = 99.99;
String nama = "John";
boolean isActive = true;
```

### Tipe Data Primitif

| Tipe Data | Ukuran | Range | Contoh |
|-----------|--------|-------|--------|
| `byte` | 1 byte | -128 to 127 | `byte b = 100;` |
| `short` | 2 bytes | -32,768 to 32,767 | `short s = 1000;` |
| `int` | 4 bytes | -2³¹ to 2³¹-1 | `int i = 100000;` |
| `long` | 8 bytes | -2⁶³ to 2⁶³-1 | `long l = 100000L;` |

---

## 4. Variable & Type Data (Lanjutan)

### Tipe Data Non-Primitif

```java
// String
String greeting = "Hello World";

// Array
int[] numbers = {1, 2, 3, 4, 5};

// Character
char grade = 'A';

// Float dan Double
float price = 19.99f;
double pi = 3.14159265359;
```

---

## 5. Aritmatika

### Operator Aritmatika

```java
int a = 10, b = 3;

// Operasi Dasar
int tambah = a + b;      // 13
int kurang = a - b;      // 7
int kali = a * b;        // 30
int bagi = a / b;        // 3
int modulo = a % b;      // 1 (sisa bagi)

// Increment & Decrement
a++;  // a = 11
b--;  // b = 2

// Assignment Operators
a += 5;  // a = a + 5
b *= 2;  // b = b * 2
```

---

## 5. Aritmatika (Lanjutan)

### Contoh Program

```java
public class Aritmatika {
    public static void main(String[] args) {
        int panjang = 10;
        int lebar = 5;
        
        int luas = panjang * lebar;
        int keliling = 2 * (panjang + lebar);
        
        System.out.println("Luas: " + luas);
        System.out.println("Keliling: " + keliling);
    }
}
```

**Output:**
```
Luas: 50
Keliling: 30
```

---

## 6. Scanner (Input/Output Java)

### Import Scanner Class

```java
import java.util.Scanner;

public class InputOutput {
    public static void main(String[] args) {
        // Membuat object Scanner
        Scanner input = new Scanner(System.in);
        
        System.out.print("Masukkan nama: ");
        String nama = input.nextLine();
        
        System.out.print("Masukkan umur: ");
        int umur = input.nextInt();
        
        System.out.println("Halo " + nama + ", umur kamu " + umur);
        
        input.close(); // Tutup Scanner
    }
}
```

---

## 6. Scanner (Lanjutan)

### Method Scanner

| Method | Deskripsi | Contoh |
|--------|-----------|--------|
| `nextInt()` | Membaca integer | `int num = input.nextInt();` |
| `nextDouble()` | Membaca double | `double d = input.nextDouble();` |
| `nextLine()` | Membaca String (satu baris) | `String s = input.nextLine();` |
| `next()` | Membaca String (satu kata) | `String word = input.next();` |
| `nextBoolean()` | Membaca boolean | `boolean b = input.nextBoolean();` |

---

## 7. Logical Operator (IF Statement)

### IF - ELSE

```java
int nilai = 75;

if (nilai >= 80) {
    System.out.println("Grade A");
} else if (nilai >= 70) {
    System.out.println("Grade B");
} else if (nilai >= 60) {
    System.out.println("Grade C");
} else {
    System.out.println("Grade D");
}
```

### Operator Perbandingan
- `==` (sama dengan)
- `!=` (tidak sama dengan)
- `>` (lebih besar)
- `<` (lebih kecil)
- `>=` (lebih besar atau sama dengan)
- `<=` (lebih kecil atau sama dengan)

---

## 7. Logical Operator (Lanjutan)

### Operator Logika

```java
int umur = 20;
boolean punyaKTP = true;

// AND (&&) - semua kondisi harus true
if (umur >= 17 && punyaKTP) {
    System.out.println("Boleh memilih");
}

// OR (||) - salah satu kondisi true
if (umur < 17 || !punyaKTP) {
    System.out.println("Tidak boleh memilih");
}

// NOT (!) - membalik boolean
if (!punyaKTP) {
    System.out.println("Harus buat KTP dulu");
}
```

---

## 7. Switch Statement

### Syntax Switch

```java
int hari = 3;
String namaHari;

switch (hari) {
    case 1:
        namaHari = "Senin";
        break;
    case 2:
        namaHari = "Selasa";
        break;
    case 3:
        namaHari = "Rabu";
        break;
    case 4:
        namaHari = "Kamis";
        break;
    case 5:
        namaHari = "Jumat";
        break;
    default:
        namaHari = "Weekend";
}

System.out.println("Hari: " + namaHari);
```

---

## 7. Nested IF

### IF Bersarang

```java
int umur = 25;
bolean punyaSIM = true;
bolean punyaMobil = true;

if (umur >= 17) {
    if (punyaSIM) {
        if (punyaMobil) {
            System.out.println("Bisa nyetir mobil sendiri");
        } else {
            System.out.println("Bisa nyetir mobil orang lain");
        }
    } else {
        System.out.println("Harus punya SIM dulu");
    }
} else {
    System.out.println("Umur belum cukup");
}
```

---

## 8. Looping - FOR Loop

### Syntax FOR

```java
// For loop dasar
for (int i = 1; i <= 5; i++) {
    System.out.println("Perulangan ke-" + i);
}

// Output:
// Perulangan ke-1
// Perulangan ke-2
// Perulangan ke-3
// Perulangan ke-4
// Perulangan ke-5
```

### Enhanced FOR (For-Each)

```java
int[] numbers = {10, 20, 30, 40, 50};

for (int num : numbers) {
    System.out.println(num);
}
```

---

## 8. Looping - FOR Loop (Contoh)

### Nested For Loop

```java
// Membuat pola bintang
for (int i = 1; i <= 5; i++) {
    for (int j = 1; j <= i; j++) {
        System.out.print("* ");
    }
    System.out.println();
}
```

**Output:**
```
* 
* * 
* * * 
* * * * 
* * * * * 
```

---

## 8. Looping - WHILE Loop

### Syntax WHILE

```java
int i = 1;

while (i <= 5) {
    System.out.println("Perulangan ke-" + i);
    i++;
}
```

### Contoh Praktis

```java
Scanner input = new Scanner(System.in);
String jawab;

while (true) {
    System.out.print("Lanjut? (ya/tidak): ");
    jawab = input.next();
    
    if (jawab.equals("tidak")) {
        break; // Keluar dari loop
    }
}
```

---

## 8. Looping - DO-WHILE Loop

### Syntax DO-WHILE

```java
int i = 1;

do {
    System.out.println("Perulangan ke-" + i);
    i++;
} while (i <= 5);
```

### Perbedaan WHILE vs DO-WHILE

- **WHILE**: Cek kondisi dulu, baru eksekusi
- **DO-WHILE**: Eksekusi dulu minimal 1x, baru cek kondisi

```java
// Ini tidak akan print apapun
int x = 10;
while (x < 5) {
    System.out.println(x);
}

// Ini akan print 10 (minimal 1x)
int y = 10;
do {
    System.out.println(y);
} while (y < 5);
```

---

## 8. Loop Control Statements

### Break & Continue

```java
// BREAK - keluar dari loop
for (int i = 1; i <= 10; i++) {
    if (i == 5) {
        break; // Stop loop saat i = 5
    }
    System.out.println(i); // Output: 1, 2, 3, 4
}

// CONTINUE - skip iterasi saat ini
for (int i = 1; i <= 5; i++) {
    if (i == 3) {
        continue; // Skip angka 3
    }
    System.out.println(i); // Output: 1, 2, 4, 5
}
}
```

---

## Contoh Program Lengkap

```java
import java.util.Scanner;

public class KalkulatorSederhana {
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        
        System.out.print("Masukkan angka pertama: ");
        double num1 = input.nextDouble();
        
        System.out.print("Masukkan operator (+, -, *, /): ");
        char operator = input.next().charAt(0);
        
        System.out.print("Masukkan angka kedua: ");
        double num2 = input.nextDouble();
        
        double hasil = 0;
        boolean valid = true;
```

---

## Contoh Program Lengkap (Lanjutan)

```java
        switch (operator) {
            case '+':
                hasil = num1 + num2;
                break;
            case '-':
                hasil = num1 - num2;
                break;
            case '*':
                hasil = num1 * num2;
                break;
            case '/':
                if (num2 != 0) {
                    hasil = num1 / num2;
                } else {
                    System.out.println("Error: Tidak bisa bagi dengan 0");
                    valid = false;
                }
                break;
            default:
                System.out.println("Operator tidak valid");
                valid = false;
        }
```

---

## Contoh Program Lengkap (Akhir)

```java
        if (valid) {
            System.out.println("Hasil: " + num1 + " " + operator + 
                             " " + num2 + " = " + hasil);
        }
        
        input.close();
    }
}
```

**Contoh Output:**
```
Masukkan angka pertama: 10
Masukkan operator (+, -, *, /): *
Masukkan angka kedua: 5
Hasil: 10.0 * 5.0 = 50.0
```

---

## Tips & Best Practices

### 📝 Tips Belajar Java

1. **Practice, practice, practice!** 💪
2. Mulai dari yang sederhana
3. Pahami error messages
4. Gunakan debugging
5. Baca dokumentasi resmi Java

### 🔗 Resources
- Oracle Java Documentation
- W3Schools Java Tutorial
- Java Programming MOOC
- Stack Overflow

---

## Kesimpulan

### Yang Sudah Dipelajari:
✅ Sejarah dan filosofi Java
✅ IDE untuk development
✅ Sintaks dan aturan Java
✅ Variable dan tipe data
✅ Operasi aritmatika
✅ Input/Output dengan Scanner
✅ Logical operators (IF, Switch, Nested)
✅ Looping (For, While, Do-While)

### Next Steps:
- Arrays dan Collections
- Object-Oriented Programming (OOP)
- Exception Handling
- File I/O

---

## Thank You! 🎉

### Questions?

**Happy Coding!** 👨‍💻👩‍💻

---