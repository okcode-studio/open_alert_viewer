/*
 * SPDX-FileCopyrightText: 2024 Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';

import 'package:bloc/bloc.dart';

import '../../../domain/alerts.dart';
import '../../../background/background.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({required BackgroundChannel bgChannel})
      : _bgChannel = bgChannel,
        accountCheckSerial = -1,
        random = Random(DateTime.now().microsecondsSinceEpoch),
        lastNeedsCheck = true,
        super(AccountInitial(
            sourceData: null,
            needsCheck: true,
            checkingNow: false,
            responded: false)) {
    on<CleanOutAccountEvent>(_cleanOut);
    on<ConfirmAccountEvent>(_confirmSource);
    on<ListenForAccountConfirmations>(_listenForConfirmations);

    add(ListenForAccountConfirmations());
  }

  final BackgroundChannel _bgChannel;
  int accountCheckSerial;
  Random random;
  bool lastNeedsCheck;

  int _genRandom() {
    return random.nextInt(1 << 32);
  }

  void _confirmSource(ConfirmAccountEvent event, Emitter<AccountState> emit) {
    bool needsCheck = lastNeedsCheck = event.needsCheck ?? false;
    bool checkNow = event.checkNow ?? false;
    if (needsCheck) {
      emit(AccountConfirmSourceState(
          sourceData: event.sourceData,
          needsCheck: true,
          checkingNow: false,
          responded: false));
    } else if (checkNow) {
      emit(AccountConfirmSourceState(
          sourceData: event.sourceData,
          needsCheck: false,
          checkingNow: true,
          responded: false));
      AlertSourceData sourceData =
          event.sourceData.copyWith(serial: accountCheckSerial = _genRandom());
      _bgChannel.makeRequest(IsolateMessage(
          name: MessageName.confirmSources, sourceData: sourceData));
    }
  }

  Future<void> _listenForConfirmations(
      ListenForAccountConfirmations event, Emitter<AccountState> emit) async {
    await for (final message in _bgChannel
        .isolateStreams[MessageDestination.accountSettings]!.stream) {
      if (message.name == MessageName.confirmSourcesReply) {
        if (message.sourceData!.serial == accountCheckSerial &&
            !lastNeedsCheck) {
          emit(AccountConfirmSourceState(
              sourceData: message.sourceData!,
              needsCheck: false,
              checkingNow: false,
              responded: true));
        }
      } else {
        throw Exception(
            "OAV Invalid 'accounts' stream message name: ${message.name}");
      }
    }
  }

  void _cleanOut(CleanOutAccountEvent event, Emitter<AccountState> emit) {
    accountCheckSerial = _genRandom();
    lastNeedsCheck = true;
    emit(AccountInitial(
        sourceData: null,
        needsCheck: true,
        checkingNow: false,
        responded: false));
  }
}