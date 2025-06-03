import { Test, TestingModule } from '@nestjs/testing';
import { WebsocketGateway } from './websocket.gateway';
import { WebsocketService } from './websocket.service';
import { Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

describe('WebsocketGateway', () => {
  let gateway: WebsocketGateway;
  let service: WebsocketService;

  const mockSocket = {
    id: 'test-client-id',
    emit: jest.fn(),
    broadcast: {
      emit: jest.fn(),
    },
    join: jest.fn(),
    leave: jest.fn(),
  } as unknown as Socket;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebsocketGateway,
        WebsocketService,
        {
          provide: Logger,
          useValue: {
            log: jest.fn(),
            error: jest.fn(),
          },
        },
      ],
    }).compile();

    gateway = module.get<WebsocketGateway>(WebsocketGateway);
    service = module.get<WebsocketService>(WebsocketService);
  });

  it('should be defined', () => {
    expect(gateway).toBeDefined();
  });

  describe('handleConnection', () => {
    it('should handle client connection', () => {
      const spy = jest.spyOn(service, 'handleConnection');
      gateway.handleConnection(mockSocket);
      expect(spy).toHaveBeenCalledWith(mockSocket);
    });
  });

  describe('handleDisconnect', () => {
    it('should handle client disconnection', () => {
      const spy = jest.spyOn(service, 'handleDisconnect');
      gateway.handleDisconnect(mockSocket);
      expect(spy).toHaveBeenCalledWith(mockSocket);
    });
  });

  describe('handleMessage', () => {
    it('should broadcast message to other clients', () => {
      const payload = { content: 'test message' };
      gateway.handleMessage(mockSocket, payload);
      expect(mockSocket.broadcast.emit).toHaveBeenCalledWith('message', {
        senderId: mockSocket.id,
        ...payload,
      });
    });
  });

  describe('handleJoinRoom', () => {
    it('should handle room joining', () => {
      const room = 'test-room';
      gateway.handleJoinRoom(mockSocket, room);
      expect(mockSocket.join).toHaveBeenCalledWith(room);
      expect(mockSocket.emit).toHaveBeenCalledWith('joinedRoom', { room });
    });
  });

  describe('handleLeaveRoom', () => {
    it('should handle room leaving', () => {
      const room = 'test-room';
      gateway.handleLeaveRoom(mockSocket, room);
      expect(mockSocket.leave).toHaveBeenCalledWith(room);
      expect(mockSocket.emit).toHaveBeenCalledWith('leftRoom', { room });
    });
  });
});
