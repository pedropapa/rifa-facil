import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema básico de Rifa',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Sistema básico de Rifa'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _ctlNome = TextEditingController();
  final FocusNode _nomeFocus = FocusNode();
  final formKey = GlobalKey<FormState>(debugLabel: 'form');
  final LocalStorage storage = new LocalStorage('rifa-lista-numeros');
  final LocalStorage associados = new LocalStorage('rifa-lista-associados');
  List numerosRifa;
  int numeroAtual;

  Map<String, int> bancoAssociados;

  @override
  void initState() {
    super.initState();

    inicializar();
  }

  void inicializar() async {
    await storage.ready;
    await associados.ready;

    if (storage.getItem('numeros') == null) {
      storage.setItem('numeros', new List<int>.generate(10000, (i) => i + 1));
    }

    if (associados.getItem('lista') == null) {
      associados.setItem('lista', new Map<String, int>());
    }

    var numbers = storage.getItem('numeros') as List;
    var listaAssociados =
        new Map<String, int>.from(associados.getItem('lista'));

    setState(() {
      numerosRifa = numbers;
      bancoAssociados = listaAssociados;
    });

    this.proximoNumero();
  }

  void proximoNumero() {
    setState(() {
      numeroAtual = numerosRifa[0];
    });
  }

  void associarNumero() {
    if (!formKey.currentState.validate()) return;

    setState(() {
      numerosRifa.remove(numeroAtual);
      storage.setItem('numeros', numerosRifa);

      bancoAssociados[_ctlNome.text] = numeroAtual;
      associados.setItem('lista', bancoAssociados);

      _ctlNome.text = '';
    });

    _nomeFocus.unfocus();

    if (numerosRifa.length > 0) {
      this.proximoNumero();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.create)),
                Tab(icon: Icon(Icons.list)),
              ],
            ),
            title: Text(widget.title),
          ),
          body: TabBarView(children: [
            _buildCriacao(),
            _buildLista(),
          ]),
        ));
  }

  List listaNomes() {
    if (bancoAssociados == null) {
      return new List<dynamic>();
    }

    var lista = bancoAssociados.values.toList();
    lista.sort((nomeA, nomeB) => nomeA.compareTo(nomeB));

    return lista;
  }

  String obterNome(int numero) {
    return bancoAssociados.keys
        .firstWhere((element) => bancoAssociados[element] == numero);
  }

  Widget _buildLista() {
    return SingleChildScrollView(
        child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 20.0),
            child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (bancoAssociados.length == 0)
                      Text(
                        'Nenhum nome associado',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    if (bancoAssociados.length > 0)
                      FlatButton(
                        onPressed: () async {
                          List<List<dynamic>> lista = new List<List<dynamic>>();

                          bancoAssociados.forEach((key, value) {
                            lista.add([key, value]);
                          });

                          String csv =
                              const ListToCsvConverter().convert(lista);

                          final directory =
                              await getApplicationDocumentsDirectory();
                          final pathOfTheFileToWrite =
                              directory.path + "/rifa-nomes.csv";
                          File file = File(pathOfTheFileToWrite);
                          await file.writeAsString(csv);

                          Share.shareFiles([file.path]);
                        },
                        padding: const EdgeInsets.all(24.0),
                        color: Colors.blue,
                        highlightColor: Colors.transparent,
                        textColor: const Color(0xFFFFFFFF),
                        shape: const Border(),
                        child: Text('Exportar como CSV'),
                      ),
                    SizedBox(
                      height: 20,
                    ),
                    Table(
                      children: [
                        if (bancoAssociados != null)
                          for (var x in listaNomes())
                            TableRow(children: [
                              TableCell(
                                  child: Container(
                                      color: (x % 2 == 0)
                                          ? Colors.grey
                                          : Colors.white,
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            SizedBox(
                                              width: 120.0,
                                              child: Text(obterNome(x)),
                                            ),
                                            Text(x.toString()),
                                            FlatButton(
                                              onPressed: () async {
                                                setState(() {
                                                  numerosRifa
                                                      .add(x);

                                                  bancoAssociados.remove(obterNome(x));
                                                  associados.setItem(
                                                      'lista', bancoAssociados);

                                                  storage.setItem(
                                                      'numeros', numerosRifa);
                                                });

                                                proximoNumero();
                                              },
                                              padding:
                                                  const EdgeInsets.all(0.0),
                                              color: Colors.red,
                                              highlightColor:
                                                  Colors.transparent,
                                              textColor:
                                                  const Color(0xFFFFFFFF),
                                              shape: const Border(),
                                              child: Text('Remover'),
                                            )
                                          ])))
                            ]),
                      ],
                    )
                  ],
                ))));
  }

  Widget _buildCriacao() {
    return Center(
        child: SafeArea(
      minimum: const EdgeInsets.only(bottom: 20.0),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Form(
              key: formKey,
              child: Column(
                children: [
                  ConstrainedText(
                    maxWidthEms: 16.0,
                    style: Theme.of(context).textTheme.subtitle1,
                    child: const Text(
                      'Digite o nome da pessoa',
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    controller: _ctlNome,
                    decoration: const InputDecoration(helperText: ''),
                    keyboardType: TextInputType.text,
                    keyboardAppearance: Brightness.light,
                    textInputAction: TextInputAction.done,
                    focusNode: _nomeFocus,
                    maxLength: 100,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                    ],
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Informe o nome';
                      }
                      if (bancoAssociados[value] != null) {
                        return 'Este nome já está associado ao número ${bancoAssociados[value]}';
                      }
                      return null;
                    },
                    maxLengthEnforced: true,
//                    onFieldSubmitted: (senha) => _confirmar(context, senha),
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            if (numerosRifa.length > 0)
              Text(
                'Número: $numeroAtual',
                style: Theme.of(context).textTheme.headline4,
              ),
            if (numerosRifa.length == 0)
              Text(
                'Não há mais números disponíveis :(',
                style: Theme.of(context).textTheme.headline4,
              ),
            SizedBox(
              height: 20.0,
            ),
            if (numerosRifa.length > 0)
              FlatButton(
                onPressed: associarNumero,
                padding: const EdgeInsets.all(24.0),
                color: Colors.blue,
                highlightColor: Colors.transparent,
                textColor: const Color(0xFFFFFFFF),
                shape: const Border(),
                child: Text('Associar'),
              )
          ],
        ),
      ),
    ));
  }
}

class ConstrainedText extends StatelessWidget {
  const ConstrainedText({
    Key key,
    @required this.maxWidthEms,
    this.minLines,
    this.style,
    this.textAlign,
    this.margin = EdgeInsets.zero,
    @required this.child,
  }) : super(key: key);

  final double maxWidthEms;
  final double minLines;
  final TextStyle style;
  final TextAlign textAlign;
  final EdgeInsetsGeometry margin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var defaultStyle = DefaultTextStyle.of(context);
    var style = defaultStyle.style.merge(this.style);
    var textAlign = this.textAlign ?? defaultStyle.textAlign;
    var child = DefaultTextStyle(style: style, child: this.child);

    if (maxWidthEms == null && minLines == null) return child;

    return Align(
      alignment: textAlign == TextAlign.center
          ? AlignmentDirectional.topCenter
          : AlignmentDirectional.topStart,
      child: Container(
        margin: margin,
        constraints: BoxConstraints(
          maxWidth: maxWidthEms == null
              ? double.infinity
              : style.fontSize * maxWidthEms,
          minHeight: minLines == null
              ? 0.0
              : minLines * (style.height ?? 1.4) * style.fontSize,
        ),
        child: child,
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text?.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
