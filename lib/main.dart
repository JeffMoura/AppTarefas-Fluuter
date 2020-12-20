import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

//CHAMA O APP
void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

//CHAMA A CLASSE HOME COM O ESTADO DA APLICAÇÃO
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
//CRIA UM CONTROLADOR PARA QUE O TEXTO DO CAMPO "NOVA TAREFA" SEJA PREENCHIDO
  final _toDoController = TextEditingController();
//CRIA UMA LISTA VAZIA
  List _toDoList = [];
//MAP PARA DESFAZER A REMOÇÃO DE ELEMENTO
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos; //volta para posição que ele foi removido

//LER OS DADOS QUANDO O APP ABRE
  @override //reescrever um método que é chamado sempre quando inicializa o estado da tela
  void initState() {
    super
        .initState(); //chama o initstate da superclasse acima "class _HomeState extends State<Home>" para ler os dados do arquivo

//observação: "_readData()" Não ocorre instantaneamente, retornando um Future.
    _readData().then((data) {
      //O uso do then é para chamar a função anonima "data", assim que o "_readData" retornar os dados.
      //Essa função anonima "data" será o String da função "Future<String> _readData() async"
      setState(() {
        //atualiza a tela após o passo abaixo
        _toDoList = json.decode(
            data); //Pegando a string do arquivo e dar um decode jason para a _toDoList
      });
    });
  }

//ADICIONA OS ITENS NA LISTA
  void _addToDo() {
    //atualiza o estado da tela à medida que adiciona um elemento na lista de tarefas
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData(); //chama esta função e salva o elemento na lista
    });
  }

  //FUNÇÃO PARA ATUALIZAR A TELA APÓS ORDENAMENTO DAS TAREFAS PRONTAS
  Future<Null> _refresh() async {
    //a função async vai fazer com que a atualização da tela no ordenamento das tarefas prontas ocorra lentamente
    await Future.delayed(
        Duration(seconds: 1)); //vai esperar 1 segundo dentro da função
    //atualiza o estado da tela
    setState(() {
      //Função de comparação "sort"
      _toDoList.sort((a, b) {
        //argumentos da função anônima (Mapas "a,b") para ordenação da lista.
        //IMPORTANTE: é preciso retornar 1 ou número positivo se a>b, retorna 0 se a=b, e retornar negativo se b>a.
        //A ideia é ordenar a lista pelas tarefas não concluídas até as concluídas
        if (a["ok"] && !b["ok"])
          return 1; //se "a" tiver concluído e "b" não tiver concluído ele retorna positivo
        else if (!a["ok"] && b["ok"])
          return -1; //se "a" não tiver concluído e "b" tiver concluído ele retorna negativo
        else
          return 0; //se ambos são iguais, retorna 0
      });
      _saveData(); //salvar o ordenamento
    });
    return null; //não precisa retornar nada (null)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //CABEÇALHO DO APP
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
              icon: Icon(
            Icons.content_paste,
            color: Colors.blueGrey,
          )),
        ],
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.greenAccent,
        centerTitle: true,
      ),
      //CORPO DO APP
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  //CAMPO DE TEXTO PARA INSERIR A TAREFA
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.greenAccent)),
                  ),
                ),
                //BOTÃO PARA ADICIONAR NOVAS TAREFAS
                RaisedButton(
                    color: Colors.redAccent,
                    child: Text("Adicionar"),
                    textColor: Colors.white,
                    onPressed: _addToDo)
              ],
            ),
          ),
          Expanded(
            //LISTVIEW QUE IRÁ EXIBIR AS TAREFAS
            child: RefreshIndicator(
              onRefresh:
                  _refresh, //irá atualizar e ordenar a lista das tarefas já concluídas
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ), //Chama a função buildItem com a lista checkboxlist
          )
        ],
      ),
    );
  }
//================FUNÇÃO QUE EXIBE OS ITENS DA LISTA

  Widget buildItem(BuildContext context, int index) {
    //tipos dos parâmetros "BuildContext e int"
    return Dismissible(
      //widget que permitirá o efeito para arrastar o item para deletar
      key: Key(DateTime.now()
          .millisecondsSinceEpoch
          .toString()), //permite identificar qual elemento da lista será deslizado, neste caso definido pelo tempo atual em milisegundos
      background: Container(
        //container para criar uma faixa de cor vermelha
        color: Colors.red,
        child: Align(
          //widget que vai ser responsável pelo alinhamento do ícone no canto esquerdo
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection
          .startToEnd, //determina a direção da esquerda para direita quando arrastar a faixa
      // A partir deste ponto chama a função que vai exibir os itens na lista
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        //chama uma função quando clica no elemento da lista e status 'true' ou 'false' muda;
        //chama a função onChanged com parâmetro c
        onChanged: (c) {
          //muda o estado atualizando a lista
          setState(() {
            _toDoList[index]["ok"] = c; //armazena o true ou false (C) no ok
            _saveData(); //chama a função e salva a opção marcada
          });
        },
      ),
      //terá uma função sempre que arrastar o item para direita para remover. O parâmetro é a direção que arrastou
      onDismissed: (direction) {
        //atualizar a lista
        setState(() {
          _lastRemoved = Map.from(
              _toDoList[index]); //duplica o item que está tentando remover
          _lastRemovedPos = index; //salva a posição que removeu
          _toDoList.removeAt(index); //Pega a TodoList e remove na posição index
          _saveData(); //Já salva a lista com o elemento removido

          final snack = SnackBar(
            //snackbar é utilizado mostrar uma informação ao usuário
            content: Text(
                "Tarefa \"${_lastRemoved["title"]}\" removida!"), //conteúdo do snackbar
            action: SnackBarAction(
              //define uma ação para a snackbar, neste caso, um botão para desfazer a ação de exclusão
              label: "Desfazer", //título da ação
              onPressed: () {
                //atualizar estado na tela
                setState(() {
                  //pega a lista e insere o elemento que removeu "_lasRemoved", na posição que já estava "_lastRemovePos"
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData(); //salva toda a ação
                });
              },
            ),
            duration: Duration(
                seconds:
                    2), //duração da ação, ao qual a mensagem para desfazer exclusão irá aparecer
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(
              snack); //mostra o snacbar construído acima na tela do app
        });
      },
    );
  }

//As funções abaixo pega toda lista, converte em json e salva no arquivo "data.jason"

//FUNÇÃO PARA OBTER O ARQUIVO
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

// =============== FUNÇÕES PARA ARMAZENAMENTO =========

//FUNÇÃO PARA SALVAR DADOS NO ARQUIVO

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

//FUNÇÃO PARA LER OS DADOS DO ARQUIVO
  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
