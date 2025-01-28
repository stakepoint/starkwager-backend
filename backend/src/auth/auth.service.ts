import { BadRequestException, Injectable } from '@nestjs/common';
import { UsersService } from 'src/users/users.service';
import { CreateUserDto } from 'src/users/dto/create-user.dto';
import * as starknet from 'starknet';
import * as jwt from 'jsonwebtoken';
import * as dotenv from 'dotenv';
dotenv.config();


@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
  ) {}

  async createOrLogin(createUserDto: CreateUserDto) {
    const { address, signature } = createUserDto;
    
    // Validate Signature
    if (signature && !(await this.isValidSignature(address, signature))) {
      throw new BadRequestException('Invalid signature');
    }

    // Check existing user by address
    const existingUser = await this.usersService.findOneByAddress(address);
    if (existingUser) {

      // If user exists generate access & refresh tokens
      const tokens = await this.generateTokens(existingUser);
      return {
        message: 'User logged in successfully',
        tokens,
      };
    }
    // If user doesn't exists, create new user and generate access & refresh tokens
    const newUser = await this.usersService.create(createUserDto);
    const tokens = await this.generateTokens(newUser);
    return {
      message: 'User Registered successfully',
      user: newUser,
      tokens,
    };
  }

  // Function to validate signature
  private async isValidSignature(address: string, signature: string): Promise<boolean> {
    try {
      const provider = new starknet.RpcProvider({ nodeUrl: 'https://your-rpc-provider-url' });
      const account = new starknet.Account(provider, address, '0x123..');
      const messageStructure = {
        types: {
          StarkNetDomain: [
            { name: 'StarkWager', type: 'felt' },
            { name: 'chainId', type: 'felt' },
            { name: 'version', type: 'felt' },
          ],
          Message: [{ name: 'message', type: 'felt' }],
        },
        primaryType: 'Message',
        domain: {
          name: 'StarkWager',
          chainId: 'SN_MAIN',
          version: '0.0.1',
        },
        message: {
          message: 'User Verified',
        },
      };

      return await account.verifyMessage(messageStructure, [signature]);
    } catch (error) {
      console.error('Signature verification failed:', error.message);
      return false;
    }
  }

  // Function to generate token
  private async generateTokens(user: any) {
    const payload = { address: user.address, sub: user.id };
    const secret = process.env.JWT_SECRET; 
    const accessToken = jwt.sign(payload, secret, { expiresIn: '15m' });
    const refreshToken = jwt.sign(payload, secret, { expiresIn: '7d' });

    return { accessToken, refreshToken };
  }
}
