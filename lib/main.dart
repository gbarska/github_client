import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:window_to_front/window_to_front.dart';

import 'github_oauth_credentials.dart';
import 'src/github_login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GitHub Client'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return GithubLoginWidget(
      builder: (context, httpClient) {
        WindowToFront.activate();
        return FutureBuilder<List<PullRequest>>(
          future: _getPullRequests(httpClient.credentials.accessToken),
          builder: (context, snapshot) {
            if(snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }

            if(!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final pullRequests = snapshot.data!;

            return Scaffold(
              appBar: AppBar(
                title: Text(title),
                elevation: 2,
              ),
              body: Center(
                child: ListView.builder(
                    itemCount: pullRequests.length,
                    itemBuilder: (context, index) {
                      final pullRequest = pullRequests[index];
                      return ListTile(
                        title: Text(pullRequest.title ?? ''),
                        subtitle: Text('flutter/flutter '
                            'PR #${pullRequest.number} '
                            'opened by ${pullRequest.user?.login ?? ''} '
                            '(${pullRequest.state?.toLowerCase() ?? ''})'),
                        onTap: () => _launchUrl(context, pullRequest.htmlUrl ?? ''),
                      );
                    }
                ),
              ),
            );


          },
        );
      },
      githubClientId: githubClientId,
      githubClientSecret: githubClientSecret,
      githubScopes: githubScopes,
    );
  }
}

Future<bool> canLaunchUrlString(String url) async {
  return url.isNotEmpty;
}

Future<void> launchUrlString(String url) async {
  return launch(url);
}

Future<void> launch(String url) async {
  // ignore: avoid_print
  print('Launching $url');
}   

Future<void> _launchUrl(BuildContext context, String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    // ignore: use_build_context_synchronously
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: const Text('Could not launch url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

Future<CurrentUser> viewerDetail(String accessToken) async {
  final gitHub = GitHub(auth: Authentication.withToken(accessToken));
  return gitHub.users.getCurrentUser();
}


Future<List<PullRequest>> _getPullRequests(String accessToken) async {
  final gitHub = GitHub(auth: Authentication.withToken(accessToken));
  return gitHub.pullRequests.list(RepositorySlug('flutter', 'flutter')).toList();
}