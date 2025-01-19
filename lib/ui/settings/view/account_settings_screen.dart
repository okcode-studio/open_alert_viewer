/*
 * SPDX-FileCopyrightText: 2024 Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_alert_viewer/ui/settings/cubit/account_settings_state.dart';

import '../../../data/services/network_fetch.dart';
import '../../../domain/alerts.dart';
import '../../core/widgets/shared_widgets.dart';
import '../cubit/account_settings_cubit.dart';
import '../widgets/settings_widgets.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen(
      {super.key, required this.title, required this.source});

  final String title;
  final AlertSourceData? source;

  static Route<void> route(
      {required String title, required AlertSourceData? source}) {
    return MaterialPageRoute<void>(
        builder: (_) => AccountSettingsScreen(title: title, source: source));
  }

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with NetworkFetch {
  _AccountSettingsScreenState()
      : nameController = TextEditingController(),
        typeController = TextEditingController(),
        baseURLController = TextEditingController(),
        userController = TextEditingController(),
        passwordController = TextEditingController(),
        accessTokenController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController typeController;
  final TextEditingController baseURLController;
  final TextEditingController userController;
  final TextEditingController passwordController;
  final TextEditingController accessTokenController;
  final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);
  bool systemIsUpdatingValues = false;
  AccountSettingsCubit? cubit;
  bool? isValid;

  @override
  void initState() {
    super.initState();
    if (widget.source == null) {
      nameController.text = "";
      typeController.text = "0";
      baseURLController.text = "";
      userController.text = "";
      passwordController.text = "";
      accessTokenController.text = "";
      isValid = null;
    } else {
      nameController.text = widget.source!.name;
      typeController.text = widget.source!.type.toString();
      baseURLController.text = widget.source!.baseURL;
      userController.text = widget.source!.username;
      passwordController.text = widget.source!.password;
      accessTokenController.text = widget.source!.accessToken;
      isValid = widget.source!.isValid;
    }
    cubit = context.read<AccountSettingsCubit>();
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    typeController.dispose();
    baseURLController.dispose();
    userController.dispose();
    passwordController.dispose();
    accessTokenController.dispose();
    cubit?.cleanOut();
  }

  AlertSourceData get newSourceData {
    if (widget.source == null) {
      return AlertSourceData(
        id: null,
        name: nameController.text,
        type: int.parse(typeController.text),
        authType: AuthTypes.basicAuth.value,
        baseURL: baseURLController.text,
        username: userController.text,
        password: passwordController.text,
        failing: false,
        lastSeen: epoch,
        priorFetch: epoch,
        lastFetch: epoch,
        errorMessage: "",
        accessToken: accessTokenController.text,
        isValid: isValid,
      );
    } else {
      return AlertSourceData(
        id: widget.source!.id,
        name: nameController.text,
        type: int.parse(typeController.text),
        authType: AuthTypes.basicAuth.value,
        baseURL: baseURLController.text,
        username: userController.text,
        password: passwordController.text,
        failing: widget.source?.failing ?? false,
        lastSeen: widget.source?.lastSeen ?? epoch,
        priorFetch: widget.source?.priorFetch ?? epoch,
        lastFetch: widget.source?.lastFetch ?? epoch,
        errorMessage: "",
        accessToken: accessTokenController.text,
        isValid: isValid,
      );
    }
  }

  void setNewSourceData({required AlertSourceData sourceData}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      systemIsUpdatingValues = true;
      nameController.text = sourceData.name;
      typeController.text = sourceData.type.toString();
      baseURLController.text = sourceData.baseURL;
      userController.text = sourceData.username;
      passwordController.text = sourceData.password;
      accessTokenController.text = sourceData.accessToken;
      isValid = sourceData.isValid;
      systemIsUpdatingValues = false;
    });
  }

  bool didDataChange() {
    final sourceData = widget.source;
    if (nameController.text == (sourceData?.name ?? "") &&
        typeController.text == (sourceData?.type.toString() ?? "0") &&
        baseURLController.text == (sourceData?.baseURL ?? "") &&
        userController.text == (sourceData?.username ?? "") &&
        passwordController.text == (sourceData?.password ?? "") &&
        accessTokenController.text == (sourceData?.accessToken ?? "")) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (!didPop) {
            final stay = await discardDialog(context: context);
            if (context.mounted && !stay) {
              Navigator.of(context).pop(false);
            }
          }
        },
        child: Scaffold(
            appBar: SettingsHeader(
                title: widget.title,
                intercept: () => discardDialog(context: context)),
            body: Center(
                child: Form(
                    autovalidateMode: AutovalidateMode.always,
                    onChanged: setNeedsCheck,
                    child: SizedBox(
                        width: 400,
                        child: BlocBuilder<AccountSettingsCubit,
                            AccountSettingsState>(builder: (context, state) {
                          cubit!.getStatusDetails(() =>
                              setNewSourceData(sourceData: state.sourceData!));
                          return ListView(children: [
                            const SizedBox(height: 20),
                            AccountRadioField(
                                title: "Third-Party Account",
                                typeController: typeController,
                                onTap: () async {
                                  String? result =
                                      await settingsRadioDialogBuilder<String>(
                                          context: context,
                                          text: "Account Type",
                                          priorSetting: typeController.text,
                                          valueListBuilder: listSourceTypes);
                                  if (result != null &&
                                      result != typeController.text) {
                                    typeController.text = result;
                                    setNeedsCheck();
                                  }
                                  return result;
                                }),
                            AccountField(
                                title: "Account Name",
                                controller: nameController,
                                validator: cubit!.generateAccountNameValidator(
                                    widget.source?.id)),
                            AccountField(
                                title: "Base URL",
                                controller: baseURLController,
                                validator: cubit!.baseUrlValidator),
                            AccountField(
                                title: "User Name", controller: userController),
                            AccountField(
                                title: "Password",
                                controller: passwordController,
                                passwordField: true),
                            const SizedBox(height: 10),
                            ListTile(
                                leading: switch (state.statusIcon) {
                                  null => null,
                                  IconType.checking => Transform.scale(
                                      scale: 0.5,
                                      child: CircularProgressIndicator(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface)),
                                  IconType.valid => Icon(Icons.check_outlined),
                                  IconType.invalid => Icon(Icons.close_outlined)
                                },
                                title: Text(state.statusText),
                                contentPadding:
                                    const EdgeInsets.fromLTRB(8, 0, 8, 0)),
                            const SizedBox(height: 10),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  cancelButton(context),
                                  acceptButton(
                                    context: context,
                                    isValid: state.sourceData?.isValid ?? false,
                                  ),
                                ]),
                            const SizedBox(height: 40),
                          ]);
                        }))))));
  }

  Widget cancelButton(BuildContext context) {
    return Expanded(
        child: Center(
            child: ElevatedButton(
                onPressed: () async {
                  if (widget.source != null) {
                    bool remove = await removeDialog(context: context);
                    if (context.mounted && remove) {
                      cubit!.removeSource(widget.source!.id!);
                      Navigator.of(context).pop(false);
                    }
                  } else {
                    bool stay = await discardDialog(context: context);
                    if (context.mounted && !stay) {
                      Navigator.of(context).pop(false);
                    }
                  }
                },
                child: Text(() {
                  if (widget.source == null) {
                    return "Cancel";
                  } else {
                    return "Remove Account";
                  }
                }(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold)))));
  }

  Widget acceptButton({required BuildContext context, required bool isValid}) {
    cubit!.setAcceptButtonText(widget.source, isValid);
    return BlocBuilder<AccountSettingsCubit, AccountSettingsState>(
        builder: (context, state) {
      return Expanded(
          child: Center(
              child: ElevatedButton(
                  onPressed: (!state.allowClickAccept)
                      ? () {}
                      : () {
                          if (Form.of(context).validate()) {
                            if (state.status == CheckStatus.needsCheck ||
                                !isValid) {
                              cubit!.confirmSource(
                                  newSourceData: newSourceData, checkNow: true);
                            } else {
                              if (widget.source == null) {
                                cubit!.addSource(newSourceData);
                              } else {
                                cubit!.updateSource(newSourceData);
                              }
                              Navigator.of(context).pop(true);
                            }
                          }
                        },
                  child: Text(state.acceptButtonText,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold)))));
    });
  }

  void setNeedsCheck() {
    if (!systemIsUpdatingValues) {
      cubit!.confirmSource(newSourceData: newSourceData, needsCheck: true);
    }
  }

  Future<bool> removeDialog({required BuildContext context}) async {
    return await textDialogBuilder(
        context: context,
        text: "Are you sure you want to remove this account?",
        okayText: "Remove",
        cancellable: true,
        reverseColors: true);
  }

  Future<bool> discardDialog({required BuildContext context}) async {
    if (didDataChange()) {
      return await textDialogBuilder(
          context: context,
          text: "Discard changes without saving?",
          cancellable: true,
          cancelText: "Discard",
          okayText: "Stay");
    } else {
      return false;
    }
  }
}

class AccountField extends StatefulWidget {
  const AccountField(
      {super.key,
      required this.title,
      required this.controller,
      this.validator,
      this.passwordField});

  final String title;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final bool? passwordField;

  @override
  State<AccountField> createState() => _AccountFieldState();
}

class _AccountFieldState extends State<AccountField> {
  late bool _textVisible;

  @override
  void initState() {
    super.initState();
    _textVisible = !(widget.passwordField ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
            alignment: Alignment.topCenter,
            child: TextFormField(
                controller: widget.controller,
                onSaved: (String? value) {},
                decoration: InputDecoration(
                  labelText: widget.title,
                  suffixIcon: widget.passwordField ?? false
                      ? IconButton(
                          icon: Icon(_textVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() => _textVisible = !_textVisible);
                          },
                        )
                      : null,
                ),
                autocorrect: false,
                enableSuggestions: false,
                obscureText: !_textVisible,
                validator: widget.validator)));
  }
}

List<SettingsRadioEnumValue> listSourceTypes<T>({T? priorSetting}) {
  return [
    for (var option in SourceTypes.values)
      if (option.value >= 0)
        SettingsRadioEnumValue<T>(
            title: option.text,
            value: option.value.toString() as T,
            priorSetting: priorSetting)
  ];
}

class AccountRadioField extends StatefulWidget {
  const AccountRadioField(
      {super.key,
      required this.title,
      required this.typeController,
      required this.onTap});

  final TextEditingController typeController;
  final String title;
  final Future<String?> Function() onTap;

  @override
  State<AccountRadioField> createState() => _AccountRadioFieldState();
}

class _AccountRadioFieldState extends State<AccountRadioField> {
  late String _name;

  String getName() {
    return SourceTypes.values
        .firstWhere((sourceType) =>
            sourceType.value.toString() == widget.typeController.text)
        .text;
  }

  @override
  void initState() {
    super.initState();
    widget.typeController.addListener(() => setState(() => _name = getName()));
    _name = getName();
  }

  @override
  build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
        child: Align(
            alignment: Alignment.topCenter,
            child: Row(children: [
              Text("${widget.title}: "),
              TextButton(
                  onPressed: widget.onTap,
                  child: Text(_name,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold)))
            ])));
  }
}
