enum MissionState { assigned, enRoute, arrived, pickedUp, completed }

extension MissionStateUi on MissionState {
  String get title {
    switch (this) {
      case MissionState.assigned:
        return 'ASSIGNED';
      case MissionState.enRoute:
        return 'EN_ROUTE';
      case MissionState.arrived:
        return 'ARRIVED';
      case MissionState.pickedUp:
        return 'PICKED_UP';
      case MissionState.completed:
        return 'COMPLETED';
    }
  }

  String get subtitle {
    switch (this) {
      case MissionState.assigned:
        return 'Mission accepted. Start driving to patient.';
      case MissionState.enRoute:
        return 'Heading to patient location.';
      case MissionState.arrived:
        return 'Ambulance has reached patient location.';
      case MissionState.pickedUp:
        return 'Patient onboard. Proceed to hospital.';
      case MissionState.completed:
        return 'Mission finished successfully.';
    }
  }
}
