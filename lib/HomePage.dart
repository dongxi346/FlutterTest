import 'dart:async';
import 'package:english_words/english_words.dart';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_app/HomeDetailPage.dart';
import 'package:flutter_app/Publish.dart';
import 'dart:convert';
import 'package:flutter_app/model/Article.dart';
import 'package:flutter_app/http/APIService.dart';


//定义一个globalKey, 由于GlobalKey要保持全局唯一性，我们使用静态变量存储
GlobalKey<ScaffoldState> _globalKey = new GlobalKey();

class HomePage extends StatefulWidget {


  HomePage(GlobalKey key) {
    _globalKey = key;
  }

  @override
  createState() => new RandomWordsState();
}

class RandomWordsState extends State<HomePage> {
  List<ArticleBean> _datas  = new List();
  int _page = 0; //加载的页数

  // 保存建议的单词对
  List<WordPair> _suggestions = new List();
  ScrollController _scrollController = new ScrollController();
  // 集合存储用户喜欢（收藏）的单词对
  final _saved = new Set<WordPair>();

  // 增大字体大小
  final _biggerFont = const TextStyle(fontSize: 18.0);
  // 副标题字体样式
  final _smallFont = const TextStyle(
      fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.red);

  // 头像样式
  final _userHeadImage = Image(
    width: 32,
    height: 32,
    image: NetworkImage("https://profile.csdnimg.cn/9/4/6/1_itxiaodong"),
    fit: BoxFit.cover,
  );

  @override
  void initState() {
    super.initState();
    getData();
    _suggestions.addAll(generateWordPairs().take(20));
    _scrollController.addListener(() {
//      print("滑动pixels："+_scrollController.position.pixels.toString());
//      print("滑动maxScrollExtent："+_scrollController.position.maxScrollExtent.toString());
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _getMoreData();
      }
    });
  }

  Future<Null> getData() async{
    _page = 0;
    print("$_page");

    APIService().getArticleList((Article _articleModel){
      setState(() {
        _datas = _articleModel.data.datas;
      });
      print("总数："+'${_articleModel.data.total}');
      print("返回的总数："+_articleModel.data.total.toString());
      print("返回的总数："+_articleModel.data.datas.length.toString());
      print("返回的title："+_datas[0].title.toString());
    }, _page);
  }

  // 处理下拉刷新
  Future _handleRefresh() async {
    await Future.delayed(Duration(seconds: 3), () {
      print('refresh');
      setState(() {
        _suggestions.clear();
        _suggestions.addAll(generateWordPairs().take(20));
        return _suggestions;
      });
    });
  }

  // 加载更多
  Future _getMoreData() async {
    print("开始加载更多");
    await Future.delayed(Duration(seconds: 3), () {
      setState(() {
        // 这里是本地数据，因此在无网的时候也会加载数据
        _suggestions.addAll(generateWordPairs().take(10));
        return _suggestions;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('首页'),
          leading: Builder(builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu), //自定义图标
              onPressed: () {
                // 打开抽屉菜单
                print("打开侧边栏");
//                Scaffold.of(context).openDrawer();
                _globalKey.currentState.openDrawer();
              },
            );
          }),
          actions: <Widget>[
            new IconButton(
                icon: new Icon(Icons.favorite), onPressed: _pushSaved),
          ],
        ),
        floatingActionButton: FloatingActionButton(
            //悬浮按钮
            child: Icon(Icons.add),
            onPressed: _onAdd),
        body: new RefreshIndicator(
          child: _buildSuggestions(),
          onRefresh: _handleRefresh,
        ));
  }

  // listView 列表
  Widget _buildSuggestions() {
    return new ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _suggestions.length + 1,
      itemBuilder: (context, i) {
        // 在每一列之前，添加一个1像素高的分隔线widget
        if (i.isOdd) return new Divider();

        // 最后一个单词对
        if (i == _suggestions.length) {
          return _buildLoadMore();
        } else {
          return _buildRow(_suggestions[i]);
        }
      },
      controller: _scrollController,
    );
  }

  // listView 每一行的内容和样式
  Widget _buildRow(WordPair pair) {
    // 检查确保单词对还没有添加到收藏夹中
    final alreadySaved = _saved.contains(pair);

    return new ListTile(
      title: new Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      subtitle: new Text(
        pair.asString,
        style: _smallFont,
      ),
      //item 前置图标
      leading: _userHeadImage,
      // item 后置图标
      trailing: new GestureDetector(
        child: new Icon(
          alreadySaved ? Icons.favorite : Icons.favorite_border,
          color: alreadySaved ? Colors.red : null,
        ),
        onTap: () {
          // 通知框架状态已经改变
          setState(() {
            if (alreadySaved) {
              _saved.remove(pair);
            } else {
              _saved.add(pair);
            }
          });
        },
      ),
      onTap: () {
        onItemClick(pair);
      },
    );
  }

  Widget _buildLoadMore() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Center(
          // 转圈加载中
          child: new CircularProgressIndicator(),
        ),
      ),
      color: Colors.white70,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void onItemClick(WordPair pair) {
    // 跳转详情页面
    Navigator.of(context).push(new MaterialPageRoute(
      builder: (context) => HomeDetailPage(
            pair: pair,
          ),
    ));
  }

  void _pushSaved() {
    // 跳转收藏页面的方法
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          final tiles = _saved.map(
            (pair) {
              return new ListTile(
                title: new Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
              );
            },
          );
          // 添加1像素的分割线
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();
          // 收藏页面
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Saved Suggestions'),
            ),
            body: new ListView(children: divided),
          );
        },
      ),
    );
  }

  void _onAdd() {
    print("点击+号");
    // 跳转详情页面
    Navigator.of(context).push(new MaterialPageRoute(
      builder: (context) => PublishPage(),
    ));
  }
}

