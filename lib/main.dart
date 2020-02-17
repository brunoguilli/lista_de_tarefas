/*
No desenvolvimento de software, as ferramentas e versões mudam muito rápido! 
Mais rápido do que é possível regravar um curso! Portando, sempre no começo de uma seção de App, 
colocarei uma aula como esta sugerindo algumas versões de plugins para você utilizar! 
Copie estas versões em algum local e utilize-as nas aulas seguintes! 
Estou sempre testando as novas versões e certificando de que elas funcionam perfeitamente, 
para que você não tenha dores de cabeça durante o curso.
As versões recomendadas para este app são:
		path_provider: ^1.1.0
Guarde-as que logo você irá utilizá-las!
Mas atenção: caso não utilize as versões sugeridas acima, há o risco do seu app não funcionar, 
e nesse caso não conseguiremos te ajudar. Por isso, utilize as versões sugeridas.
*/
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // Permite ler e gravar em arquivo JSON (Facilita gravar arquivos IOS e ANDROID)
import 'dart:async';
import 'dart:io';

void main(){
  runApp(MaterialApp(
    home: Home(),
  ));
}

// Digitar stful para ir mais rapido
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];
  
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos; 

  // Sobrescreve o metodo que é sempre utilizado quando atualizamos o estado do widget
  // Vamos carregar a lista sempre inicializarmos o app ou quando atualizarmos o widget
  @override
  void initState() {
    super.initState();
  
  // Assim que reronarem os dados no readData, então (then) executa a função 
    _readData().then((data){
      setState(() {
        _toDoList = json.decode(data);  
      });
    });
  }

  // Responsável por adicionar os dados na lista e salva-los em um arquivo
  void _addToDo(){
    setState(() { // Atualiza o estado da tela assim que adicionar um novo elemento na lista
      Map<String,dynamic> newToDo = Map(); // String e Dynamic para lidar com JASON // Map() -> Mapa vazio
      newToDo["title"] = _toDoController.text; 
      _toDoController.text = ""; // Assim que clicar no botão para adiocionar nova tarefa, o texto "Nova tarefa" será resetado
      newToDo["ok"] = false; // Inicializando tarefa com o valor false, pois ela não foi concluída ainda
      _toDoList.add(newToDo); // Adicionamos um elemento MAP na lista
      _saveData();
    });
  }

  // Função Future sem retorno, o async é pq vai demorar 1 segundo para atualizar
  Future<Null> _refresh() async { 
    // Espera 1 segundo dentro da função
    await Future.delayed(Duration(seconds: 1));

      // Atualiza a tela
      setState(() {
        // Ordenação: O sort precisa de dois argumentos, a função irá comparar esses elementos
        // O retorno dessa função será 1(primeiro elemento maior que o segundo) -1(segundo maior que o primeiro) ou 0(igual)
        _toDoList.sort((a, b){
          if(a["ok"] && !b["ok"]) return 1;
          else if(!a["ok"] && b["ok"]) return -1;
          else return 0; 
        });
        _saveData();
      });
      return null;  
  } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded( // Vai expandir nosso campo de texto, possibilitando colocar o button ao lado
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh,
              child: ListView.builder( // Permite que eu construa minha lista conforme for adicionando elementos
              padding: EdgeInsets.only(top: 10.0),// Para não ficar colado com o container acima
              itemCount: _toDoList.length, // Quantidade de itens na lista
              itemBuilder:  buildItem
            ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(context,index){  // Monta a lista conforme o index da itemCount passando de parâmetro para a função ListTile
      // Widget que permite que eu arraste o item para a direita para deletar ele
      return Dismissible(
        // Key: Index para saber qual item que estamos deslizando, nesse caso estamos utilizando DateTime como identificador único
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()), 
        background: Container( // Quando deslizar
          color: Colors.red, // Cor da barra
          child: Align(
            alignment: Alignment(-0.9, 0.0), // Posição do ícone
            child: Icon(Icons.delete,color: Colors.white), // ícone = Lixeira
          ),
        ),
        direction: DismissDirection.startToEnd, // Dislizar do começo para o fim
        child: CheckboxListTile(
          title: Text(_toDoList[index]["title"]),
          value: _toDoList[index]["ok"],
          secondary: CircleAvatar(
            child: Icon(_toDoList[index]["ok"] ?
              Icons.check : Icons.error 
            ),
          ),
          onChanged: (c){ // É chamado quando eu clico em um elemento da lista // Parâmetro 'C' poder ser true ou false
            setState(() { // Atualiza a lista com o novo estado
              _toDoList[index]["ok"] = c; // Armazena true ou false no OK 
              _saveData();
            });
          }, // Chama uma função quando o status de true ou false muda 
        ),
        onDismissed: (direcion){
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);  // Duplicando o item que estou removendo
            _lastRemovedPos = index; // Salvando a posição do item
            _toDoList.removeAt(index); // Remove o item da lista

            _saveData(); // Salva a lista com o item removido

            final snack = SnackBar(
              content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
              action: SnackBarAction(label: "Desfazer",
                onPressed: (){
                  setState(() {
                    // Passa a posição e o elemnto em si para retornar a lista
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    // Salva o elemento novamente na lista
                    _saveData();
                  });
                },
              ),
              duration: Duration(seconds: 2),
            );

            //Remove a Snackbar atual antes de mostrarmos a nova. Assim elas não irão ser empilhadas
            Scaffold.of(context).removeCurrentSnackBar(); 

            // Comando para exibir o snackbar criado
            Scaffold.of(context).showSnackBar(snack); 
           

          });
        },
      );
    } // Elementos da lista


  Future<File> _getFile() async {// Função que retorna o arquivo que iremos utilizar para salvar
  final directory = await getApplicationDocumentsDirectory(); // Pega o diretorio aonde eu posso armazenar os docs do app
                                                              // Comando awayt porque o comando retorna um future
  print("directory path - "+directory.path);
  return File('${directory.path}/tarefas.json'); // Criando um arquivo chamado tarefas
  }

  Future<File> _saveData() async { // async : Tudo que envolve salvamento de arquivos não ocorre instantaneamente
    String data = json.encode(_toDoList); // Transformando a lista em JSON e armazenando em uma string
    final file = await _getFile(); // Vai esperar o meu arquivo
    return file.writeAsString(data); // Escrevendo os dados da lista no arquivo retornado
  }

  Future<String> _readData() async {
    try{ // Tenta fazer algo
      final file = await _getFile();
      return file.readAsString();
    } catch (e) { // Caso der errado 
      return null;
    }
  }

}

