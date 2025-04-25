class Args {
  Args({
    this.build = const <String, String>{},
    this.deploy = const <String, String>{},
  });

  const Args.empty()
      : build = const <String, String>{},
        deploy = const <String, String>{};

  final Map<String, String> build;
  final Map<String, String> deploy;
}
