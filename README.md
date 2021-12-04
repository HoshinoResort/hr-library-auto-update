# hr-library-auto-update

[maven](https://maven.apache.org/) でパッケージ管理を行うプロジェクトの依存ライブラリのバージョンを自動更新するためのカスタム GitHub Action です。プロジェクト非依存で利用します。

## 前提条件

* [Maven Wrapper](https://github.com/takari/maven-wrapper) (mvnw スクリプト) をリポジトリのルートディレクトリに置く
* [Versions Maven Plugin](https://www.mojohaus.org/versions-maven-plugin/) でバージョン管理を行う
  * 次のような設定を `pom.xml` に追加する

```xml
    <build>
        <plugins>
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>versions-maven-plugin</artifactId>
                <version>2.8.1</version>
                <configuration>
                </configuration>
            </plugin>
        </plugins>
    </build>
```

## 使い方

```yml
- name: Update library versions
  uses: HoshinoResort/hr-library-auto-update@v1
  with:
    # maven コマンドで実行するテスト向けのコマンドを指定する
    # デフォルト: test
    maven-test-command: ''

    # maven コマンドの --settings オプションに渡す settings.xml への相対パス
    # デフォルト: 未使用
    maven-settings-xml-path: ''

    # Versions Maven Plugin のアップデートルールを記述する rules.xml への相対パス
    # デフォルトでは本リポジトリにある rules.xml の設定を利用する
    # デフォルト: 未使用
    custom-rules-xml-path: ''

    # versions:display-dependency-updates でバージョンの更新をチェックする
    # このコマンドはすべての依存ライブラリに対してメジャーバージョンの更新も含めてチェックする
    # 不要なら無効にすることで処理時間を短縮できる
    # デフォルト: 'false'
    display-dependency-updates: ''

    # GitHub Actions が提供するビルドキャッシュ (actions/cache) を利用するかどうか
    # ビルドキャッシュを利用することでバージョンチェックの処理を高速化できる
    # デフォルト: 'true'
    use-cache: ''

    # GitHub Actions が提供するビルドキャッシュ (actions/cache) に渡すパス
    # キャッシュの除外設定に利用することを想定している
    # デフォルト: 未使用
    custom-cache-path: ''

    # テストコマンドが成功したときにバージョンの更新をリポジトリに反映するかどうか
    # バージョンのアップデートがあるかどうかをチェックしたいだけなら無効でよい
    # デフォルト: 'false'
    push-on-success: ''

    # デバッグ用途に冗長モードを有効にするかどうか
    # デフォルト: 'false'
    verbose: ''
```

### 呼び出し側の設定例

```yml
- name: Update library versions
  uses: HoshinoResort/hr-library-auto-update@v1
  with:
    maven-test-command: "test -DfailIfNoTests=false -Dtest='!IntegrationTest'"
    maven-settings-xml-path: "${{ github.workspace }}/settings.xml"
    custom-cache-path: '!~/.m2/repository/com/subdomain'
    push-on-success: 'true'
```

`custom-cache-path` は [actions/cache](https://github.com/actions/cache) に渡す `path` を記述します。`!` を使うことでキャッシュ対象から除外できます。この例では `~/.m2/repository/com/subdomain` 配下のディレクトリをすべてキャッシュしない設定になります。

リポジトリに push するには GITHUB_TOKEN や permissions といった認証情報を適切に設定する必要があります。

```yml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    env:
        GITHUB_TOKEN: ${{ secrets.MY_TOKEN }}
```

#### リファレンス

* [GitHub Actions / Security guides / Automatic token authentication](https://docs.github.com/ja/actions/security-guides/automatic-token-authentication)
* [GitHub Actions / Learn GitHub Actions / Workflow syntax / permissions](https://docs.github.com/ja/actions/learn-github-actions/workflow-syntax-for-github-actions#onworkflow_dispatchinputs)

## FAQ

* 最新のメジャーバージョンにアップデートしません
  * 事故を防ぐ意図で `allowMajorUpdates=false` で防止しています
  * メジャーバージョンを上げたいときは手動でプロジェクトの `pom.xml` のバージョンを更新してください
* 特定の文字列を含むバージョンを無視してほしい
  * 汎用的なバージョン文字列であれば本リポジトリの `rules.xml` に含めるのでイシューを作成してください
  * プロジェクト特有の要件であれば、自プロジェクトで `rules.xml` を定義して `custom-rules-xml-path` で指定してください
* こういった機能や設定を追加してほしい
   * プロジェクト非依存の汎用的な機能であれば検討するのでイシューを作成してください

## 開発者向け

基本的にローカルで maven コマンドを実行して検証できるよう `functions.sh` にシェル関数として実装しています。機能拡張するときはローカルでデバッグができることを意識して開発してください。

### デバッグ

`functions.sh` を読み込んで直接シェル関数を呼び出します。

```bash
$ source path/to/hr-library-auto-update/functions.sh && mvnw_version

$ ./mvnw --no-transfer-progress --version
Apache Maven 3.6.3 (cecedd343002696d0abb50b32b541b8a6ba2883f)
Maven home: path/to/.m2/wrapper/dists/apache-maven-3.6.3-bin/1iopthnavndlasol9gbrbg6bf2/apache-maven-3.6.3
Java version: 11.0.11, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64
Default locale: ja_JP, platform encoding: UTF-8
OS name: "linux", version: "5.11.0-40-generic", arch: "amd64", family: "unix"
```

### テスト

まとめてテストを実行するために `do_test` というシェル関数を定義しています。

```bash
$ source functions.sh && do_test
```

## リファレンス

* [Versions Maven Plugin](https://www.mojohaus.org/versions-maven-plugin/index.html)
* [GitHub Actions / アクションの作成](https://docs.github.com/ja/actions/creating-actions)
