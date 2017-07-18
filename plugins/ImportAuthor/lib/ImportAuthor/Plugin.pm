package ImportAuthor::Plugin;

use strict;
use utf8;
use File::Temp qw(tempdir);
use File::Copy::Recursive qw(dircopy);
use MT::Util::Archive;
use MT::Role;
use MT::Association;

sub upload_author_condition {
	my $app = MT->instance;
	my $blog_id = $app->param('blog_id') || '';
	return $app->user->permissions($blog_id)->can_do('upload_author');
}

# display upload form
sub upload_author {
	my $app = shift;
	my ($errors) = @_;
	my $blog_id = $app->param('blog_id') || '';
	return $app->return_to_dashboard( permission => 1)
		unless $app->user->permissions($blog_id)->can_do('upload_author');

	my $plugin = MT->component('ImportAuthor');

	# params
	my $saved = $app->param('saved') || '';

	# display
	my %param = (
		blog_id => $blog_id,
		errors => $errors,
		saved => $saved,
	);
	my $html = $app->load_tmpl('upload_author.tmpl', \%param);
	return $app->build_page($html, \%param);
}


# process
sub process_upload_author {
	my $app = shift;
	my $q = $app->param;
	my $blog_id = $app->param('blog_id') || '';
	return $app->return_to_dashboard( permission => 1)
		unless $app->user->permissions($blog_id)->can_do('process_upload_author');

	my $plugin = MT->component('ImportAuthor');

	# params
	my ($fh, $nfo) = $app->upload_info('csv_file');

	# validation
	my @errors;
	my @datas;
	if (!$fh) {
		push @errors, $plugin->translate('File not uploaded.');
	} else {
		my $csv_file = $q->tmpFileName($fh);
		if (!$csv_file) {
			push @errors, $plugin->translate('File not uploaded.' . $csv_file);
		} else {
			# read data
			@datas = _read_data($app, $csv_file);
			if ($app->errstr) {
				push @errors, $app->errstr;
			} else {
				_validate_csv($app, $plugin, \@datas, \@errors);
			}
		}
	}

	# back to form if error exists
	if (@errors) {
		return upload_author($app, \@errors);
	}

	foreach my $data (@datas) {
		# regist author
		my $author = MT::Author->load({name => $data->{name}});
		if (!$author) {
			$author = MT::Author->new;
			if ($data->{id}) {
				$author->id($data->{id});
			}
		}
		if ($data->{id} && $data->{id} ne $author->id) {
			return $app->error($app->translate("A user with the same name already exists. [_1]", $data->{name}));
		}
		$author->set_values({
			auth_type => 'MT',
			name     => $data->{name},
			nickname => $data->{nickname},
			email    => $data->{email},
			url      => $data->{url},
		});
		$author->set_password($data->{password});
		$author->save or return $app->error($author->errstr);
		$app->log({message => "ImportAuthor: " . $plugin->translate("Author was imported. [_1](#[_2])", $author->name, $author->id)});

		# remove roles
		my @associations = MT::Association->load({author_id => $author->id});
		foreach my $association (@associations) {
			$association->remove or return $app->error($association->errstr);
		}
		# regist roles
		foreach my $role_data (@{$data->{role}}) {
			my $blog = MT::Blog->load($role_data->{blog_id});
			my $role = MT::Role->load($role_data->{role_id});
			$author->add_role($role, $blog) or return $app->error($author->errstr);
			$app->log({message => "ImportAuthor: " . $plugin->translate("Role was added. {author:[_1](#[_2]), blog:[_3](#[_4]), role:[_5](#[_6])}", $author->name, $author->id, $blog->name, $blog->id, $role->name, $role->id)});
		}
	}

	return $app->redirect($app->uri(
		mode => 'upload_author', 
		args => {
			blog_id => $blog_id, 
			saved => 1,
	}));
}


# read csv file
sub _read_data {
	my ($app, $filename) = @_;

	my @datas;

	open DATA, "<:encoding(Shift_JIS)", $filename
		or return $app->error("cannot open $filename");

	my $cnt = 0;
	while (my $line = <DATA>) {
		$line .= <DATA> while ($line =~ tr/"// % 2 and !eof(DATA));
		$line =~ s/(?:\x0D\x0A|[\x0D\x0A])?$/,/;
		my @values = map {/^"(.*)"$/s ? scalar($_ = $1, s/""/"/g, $_) : $_}
                ($line =~ /("[^"]*(?:""[^"]*)*"|[^,]*),/g);

		$cnt++;
		next if $cnt == 1;
		my $data = undef;
		$data->{id}          = $values[0];
		$data->{name}        = $values[1];
		$data->{password}    = $values[2];
		$data->{nickname}    = $values[3];
		$data->{email}       = $values[4];
		$data->{url}         = $values[5];
		my @roles = map {
			my ($blog_id, $role_id) = split('_', $_);
			{blog_id => $blog_id, role_id => $role_id};
		} split('&', $values[6]);
		$data->{role}        = \@roles;
		push @datas, $data;
	}
	close DATA;

	return @datas;
}


# validate csv
sub _validate_csv {
	my ($app, $plugin, $datas, $errors) = @_;

	my @requires = (
		'name',
		'password',
		'nickname',
		'email',
	);
	for (my $i = 0; $i < @$datas; $i++) {
		foreach my $key (@requires) {
			if (!$$datas[$i]->{$key}) {
				push @$errors, $plugin->translate('CSV Line #[_1] error: [_2] is null.', $i+1, $plugin->translate($key));
			}
		}
		foreach my $role_data (@{$$datas[$i]->{role}}) {
			if (!$role_data->{blog_id} || $role_data->{blog_id} =~ m/\D/) {
				push @$errors, $plugin->translate('CSV Line #[_1] error: Wrong role blog_id [_2].', $i+1, $role_data->{blog_id});
			} else {
				my $blog = MT::Blog->load($role_data->{blog_id});
				if (!$blog) {
					push @$errors, $plugin->translate('CSV Line #[_1] error: Not found blog #[_2].', $i+1, $role_data->{blog_id});
				}
			}
			if (!$role_data->{role_id} || $role_data->{role_id} =~ m/\D/) {
				push @$errors, $plugin->translate('CSV Line #[_1] error: Wrong role role_id [_2].', $i+1, $role_data->{role_id});
			} else {
				my $role = MT::Role->load($role_data->{role_id});
				if (!$role) {
					push @$errors, $plugin->translate('CSV Line #[_1] error: Not found role #[_2].', $i+1, $role_data->{role_id});
				}
			}
		}
	}
}

1;
