package ImportAuthor::L10N::ja;

use strict;
use base qw( ImportAuthor::L10N::en_us );
use vars qw( %Lexicon );

%Lexicon = (
	'_AUTHOR_NAME' => 'ark-web',
	'_PLUGIN_DESCRIPTION' => 'ユーザーインポートプラグイン',
	'ImportAuthor' => 'ユーザーインポート',
	'Select File' => 'ファイルを選択',
	'Required' => '必須項目です',
	'File not uploaded.' => 'ファイルがアップロードされませんでした。',
	'Not found CSV file in [_1].' => '[_1]にCSVファイルがありません。',
	'CSV error: [_1] is null.' => 'CSVエラー: [_1]が空です。',
	'Authors has been imported.' => 'ユーザーをインポートしました。',
	'Author was imported. [_1](#[_2])' => 'ユーザーをインポートしました。[_1](#[_2])',
	'Role was added. {author:[_1](#[_2]), blog:[_3](#[_4]), role:[_5](#[_6])}' => 'ロールを追加しました。 {ユーザー:[_1](#[_2]), ブログ:[_3](#[_4]), ロール:[_5](#[_6])}',
	'CSV Line #[_1] error: [_2] is null.' => 'CSVエラー #[_1]行目: [_2]が空です。',
	'CSV Line #[_1] error: Wrong role blog_id [_2].' => 'CSVエラー #[_1]行目: blog_idが正しくありません。[_2]',
	'CSV Line #[_1] error: Not found blog #[_2].' => 'CSVエラー #[_1]行目: ブログが見つかりませんでした。#[_2]',
	'CSV Line #[_1] error: Wrong role role_id [_2].' => 'CSVエラー #[_1]行目: role_idが正しくありません。[_2]',
	'CSV Line #[_1] error: Not found role #[_2].' => 'CSVエラー #[_1]行目: ロールが見つかりませんでした。#[_2]',
	'A user with the same name already exists. [_1]' => '同名のユーザーが既に存在します。 [_1]',
);

1;
